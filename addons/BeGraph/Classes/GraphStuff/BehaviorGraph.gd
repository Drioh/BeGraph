@tool
class_name BehaviorGraph
extends Resource

##Blackboard with values that don't get shared between different instances of this graph
@export var blackboard: Array[BlackboardVariable]:
	set(v):
		if v: blackboard=v
		changed.emit(blackboard)

@export_group("Graph Properties")

##BehaviorNodes contained in this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var nodes : Array[BehaviorNode]:
	set(v):
		nodes=v
		for n in nodes:
			if n: n._graph_ref=weakref(self)
##Used for saving purposes, this variable contains a copy of [param connections] from the graph edit. This value gets its value when a graph gets saved
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var connections : Array[Dictionary]

func _init() -> void:
	if nodes.size()==0:
		var first_node = AccessPointNode.new()
		first_node.resource_name = "start_node"
		add_node(first_node)


#region Node methods
func add_node(node:BehaviorNode):
	node._graph_ref=weakref(self)
	nodes.append(node)

func remove_node(node:BehaviorNode):
	nodes.erase(node)

func add_connection(connection:Dictionary):
	connections.append(connection)

func remove_connection(connection:Dictionary):
	connections.erase(connection)

func get_nodes_by_category(category : String) -> Array[BehaviorNode]:
	var ret : Array[BehaviorNode] = []
	for node in nodes:
		if node.node_category == category: 
			ret.append(node)
	if ret.is_empty():
		push_error("Nodes not found for category '%s'"%category)
	return ret

func get_node(name:StringName)->BehaviorNode:
	for node in nodes:
		if node.resource_name==name:
			return node
	push_error("Node '%s' not found"%name)
	return
#endregion

func get_blackboard_property(key:StringName)->BlackboardVariable:
	for variable in blackboard:
		if variable.name == key:
			return variable
	push_error("Key '%s' not found inside of '%s''s blackboard"%[key,self])
	return null
