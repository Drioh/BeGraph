@tool
## Resource describing a full behavior graph: the collection of [BehaviorNode]s it contains, the connections between them, and its own local [BlackboardVariable] list. Instantiated and edited through [BehaviorGraphEdit] and executed at runtime by one or more [BehaviorAgent]s.
class_name BehaviorGraph
extends Resource

##Blackboard with values that don't get shared between different instances of this graph
@export var blackboard: Array[BlackboardVariable]:
	set(v):
		if v: blackboard=v
		changed.emit(blackboard)

@export_group("Graph Properties")

##BehaviorNodes contained in this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var nodes : Dictionary[StringName,BehaviorNode]:
	set(v):
		nodes=v
		for n in nodes.values():
			if n: n._graph_ref=weakref(self)
##Used for saving purposes, this variable contains a copy of [param connections] from the graph edit. This value gets its value when a graph gets saved
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var connections : Array[Dictionary]

##The agent running this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var _agent_ref : WeakRef = weakref(null)

## Creates the graph's first [AccessPointNode] (named [code]"start_node"[/code]) if [member nodes] is empty, guaranteeing every new [BehaviorGraph] has at least one valid entry point.
func _init() -> void:
	if nodes.size()==0:
		var first_node = AccessPointNode.new()
		first_node.resource_name = "start_node"
		add_node(first_node)


#region Node methods

## Appends [param node] to [member nodes] and points its [member BehaviorNode._graph_ref] back to this graph.
func add_node(node:BehaviorNode):
	node._graph_ref=weakref(self)
	nodes[StringName(node.resource_name)]=node

## Removes [param node] from [member nodes].
func remove_node(node:BehaviorNode):
	nodes.erase(node.resource_name)

## Appends [param connection] (a [code]{from_node, from_port, to_node, to_port}[/code] [Dictionary]) to [member connections].
func add_connection(connection:Dictionary):
	connections.append(connection)

## Removes [param connection] from [member connections].
func remove_connection(connection:Dictionary):
	connections.erase(connection)

## Returns every [BehaviorNode] in [member nodes] whose [member BehaviorNode.node_category] matches [param category]. Logs an error (and returns an empty array) if no node matches.
func get_nodes_by_category(category : String) -> Array[BehaviorNode]:
	var ret : Array[BehaviorNode] = []
	for node in nodes.values():
		if node.node_category == category: 
			ret.append(node)
	if ret.is_empty():
		push_error("Nodes not found for category '%s'"%category)
	return ret

## Returns every [BehaviorNode]'sname in [member nodes] whose [member BehaviorNode.node_category] matches [param category]. Logs an error (and returns an empty array) if no node matches.
func get_nodes_names_by_category(category : String) -> Array[StringName]:
	var ret : Array[StringName] = []
	for node in nodes.values():
		if node.node_category == category: 
			ret.append(node.resource_name)
	if ret.is_empty():
		push_error("Nodes not found for category '%s'"%category)
	return ret

## Returns the [BehaviorNode] in [member nodes] whose [member Resource.resource_name] matches [param name], or [code]null[/code] (logging an error) if none is found.
func get_node(name:StringName)->BehaviorNode:
	for node in nodes.values():
		if node.resource_name==name:
			return node
	push_error("Node '%s' not found"%name)
	return
#endregion

## Returns the [BlackboardVariable] in [member blackboard] named [param key], or [code]null[/code] (logging an error) if none is found.
func get_blackboard_property(key:StringName)->BlackboardVariable:
	for variable in blackboard:
		if variable.name == key:
			return variable
	push_error("Key '%s' not found inside of '%s''s blackboard"%[key,self])
	return null

func set_agent(n: Node) -> void:
	_agent_ref = weakref(n)

func get_agent_node() -> Node:
	return _agent_ref.get_ref()

## Prepares a freshly duplicated graph for execution: binds it to [param agent], rebuilds successor links from [member connections] and points every node back to this graph.
func setup_runtime(agent: Node) -> void:
	set_agent(agent)
	for c in connections:
		var from_node : BehaviorNode = get_node(c["from_node"])
		var to_node : BehaviorNode = get_node(c["to_node"])
		if from_node == null or to_node == null:
			push_error("Can't build connection %s -> %s" % [c["from_node"], c["to_node"]])
			continue
		from_node.add_next(to_node, c["from_port"])
	for node in nodes.values():
		node._graph_ref = weakref(self)
