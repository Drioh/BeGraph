@tool
## Resource describing a full behavior graph: the collection of [BehaviorNode]s it contains, the connections between them, and its own local [BlackboardVariable] list. Instantiated and edited through [BehaviorGraphEdit] and executed at runtime by one or more [BehaviorAgent]s.
class_name BehaviorGraph
extends Resource

signal blackboard_value_changed(key: StringName, value: Variant)

##Blackboard with values that don't get shared between different instances of this graph
@export var blackboard: Array[BlackboardVariable]:
	set(v):
		if v != null:
			blackboard = v
			_rebuild_blackboard_map()
		changed.emit()

@export_group("Graph Properties")

##BehaviorNodes contained in this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) 
var nodes : Dictionary[StringName,BehaviorNode]:
	set(v):
		nodes=v
		for n in nodes.values():
			if n: n._graph_ref=weakref(self)
##Used for saving purposes, this variable contains a copy of [param connections] from the graph edit. This value gets its value when a graph gets saved
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) 
var connections : Array[Dictionary]

##The agent running this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) 
var _agent_ref : WeakRef = weakref(null)

## O(1) lookup cache mapping variable name -> BlackboardVariable instance.
var _blackboard_map : Dictionary[StringName, BlackboardVariable] = {}
## O(1) runtime cache mapping absolute NodePath -> WeakRef(Node) for _resolve_node().
var _resolved_nodes_cache : Dictionary[NodePath, WeakRef] = {}

## Creates the graph's first [AccessPointNode] if [member nodes] is empty, guaranteeing every new [BehaviorGraph] has at least one valid entry point.
func _init() -> void:
	if not nodes.is_empty(): return
	
	var first_node = AccessPointNode.new()
	first_node.resource_name = StringName("_GraphNode_%d" % randi_range(10000, 99999))
	add_node(first_node)


#region Node methods

## Appends [param node] to [member nodes] and points its [member BehaviorNode._graph_ref] back to this graph.
func add_node(node: BehaviorNode) -> void:
	if node == null: return
	
	node._graph_ref = weakref(self)
	nodes[StringName(node.resource_name)] = node

## Removes [param node] from [member nodes].
func remove_node(node: BehaviorNode) -> void:
	if node == null: return
	
	nodes.erase(node.resource_name)

## Appends [param connection] (a [code]{from_node, from_port, to_node, to_port}[/code] [Dictionary]) to [member connections].
func add_connection(connection:Dictionary):
	connections.append(connection)

## Removes [param connection] from [member connections].
func remove_connection(connection:Dictionary):
	connections.erase(connection)

## Returns the [BehaviorNode] in [member nodes] whose [member Resource.resource_name] matches [param name], or [code]null[/code] (logging an error) if none is found.
func get_node(name:StringName)->BehaviorNode:
	var n = nodes.get(name, null)
	if n == null:
		push_error("BehaviorGraph: Node '%s' not found" % name)
	return n

## Returns every [BehaviorNode] in [member nodes] whose [member BehaviorNode.node_category] matches [param category]. Logs an error (and returns an empty array) if no node matches.
func get_nodes_by_category(category : String) -> Array[BehaviorNode]:
	var ret : Array[BehaviorNode] = []
	for node in nodes.values():
		if node == null or node.node_category != category: continue
		
		ret.append(node)
	if ret.is_empty():
		push_error("BehaviorGraph: Nodes not found for category '%s'"%category)
	return ret

## Returns every [BehaviorNode]'s name in [member nodes] whose [member BehaviorNode.node_category] matches [param category]. Logs an error (and returns an empty array) if no node matches.
func get_nodes_names_by_category(category: String) -> Array[StringName]:
	var names : Array[StringName] = []
	for node in get_nodes_by_category(category):
		names.append(node.resource_name)
	return names

#endregion

#region Blackboard Methods
## Rebuilds [member _blackboard_map] from [member blackboard] and connects variable rename signals.
func _rebuild_blackboard_map() -> void:
	_blackboard_map.clear()
	for variable in blackboard:
		if variable == null: continue
		if not variable.name_changed.is_connected(_on_variable_name_changed):
			variable.name_changed.connect(_on_variable_name_changed)
		if variable.name != &"":
			_blackboard_map[variable.name] = variable

func _on_variable_name_changed(_new_name: String) -> void:
	_rebuild_blackboard_map()

## Returns the [BlackboardVariable] in [member blackboard] named [param key], or [code]null[/code] if none is found.
func get_blackboard_property(key: StringName) -> BlackboardVariable:
	var cached : BlackboardVariable = _blackboard_map.get(key, null)
	if cached != null and cached.name == key:
		return cached
	for variable in blackboard:
		if variable == null or variable.name != key: continue
		_blackboard_map[key] = variable
		return variable
	return null

func get_blackboard_value(key: StringName, default_value: Variant = null) -> Variant:
	var prop :BlackboardVariable = get_blackboard_property(key)
	return prop.value if prop != null else default_value 

func set_blackboard_value(key: StringName, value: Variant) -> void:
	var prop := get_blackboard_property(key)
	if prop == null:
		push_error("BehaviorGraph: key '%s' not found inside blackboard" % key)
		return
	if prop.value != value:
		prop.value = value
		blackboard_value_changed.emit(key, value)
#endregion

func set_agent(n: Node) -> void:
	_agent_ref = weakref(n)

func get_agent_node() -> BehaviorAgent:
	return _agent_ref.get_ref() as BehaviorAgent

## Prepares a freshly duplicated graph for execution: binds it to [param agent], rebuilds successor links from [member connections] and points every node back to this graph.
func setup_runtime(agent: Node, source_graph: BehaviorGraph = null) -> void:
	if source_graph != null:
		for i in source_graph.blackboard.size():
			var src_var : BlackboardVariable = source_graph.blackboard[i]
			if src_var != null and not src_var.resource_path.is_empty() and not src_var.is_built_in():
				blackboard[i] = src_var
	set_agent(agent)
	_resolved_nodes_cache.clear()
	_rebuild_blackboard_map()
	
	for c in connections:
		var from_node : BehaviorNode = get_node(c["from_node"])
		var to_node : BehaviorNode = get_node(c["to_node"])
		if from_node == null or to_node == null:
			push_error("BehaviorGraph: Can't build connection %s -> %s" % [c["from_node"], c["to_node"]])
			continue
		
		from_node.add_next(to_node, c["from_port"])
	
	for node in nodes.values():
		node._graph_ref = weakref(self)
		if node._blackboard_bindings.is_empty() or not node.has_method(&"on_blackboard_property_changed"): continue
		
		node._connect_blackboard_signals()
	
	for node in nodes.values():
		if node is BehaviorFrame and node.is_sequence:
			node.setup_sequence(self)
