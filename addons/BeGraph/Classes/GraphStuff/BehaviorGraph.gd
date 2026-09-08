@tool
class_name BehaviorGraph
extends Resource

@export_group("Blackboards")

##Blackboard with values that don't get shared between different instances of this graph
@export var local_blackboard: BehaviorGraphBlackboard:
	set(value):
		if value == local_blackboard:
			return
		if value != null:
			local_blackboard = value.duplicate(true)
		else:
			local_blackboard = null

##Blackboard with values that get shared between different instances of this graph
@export var shared_blackboard: BehaviorGraphBlackboard:
	set(value):
		if value == shared_blackboard:
			return
		if value != null:
			shared_blackboard = value
		else:
			shared_blackboard = null

@export_group("Graph Properties")

##BehaviorNodes contained in this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var nodes : Array[BehaviorNode]
##Used for saving purposes, this variable contains a copy of [param connections] from the graph edit. This value gets its value when a graph gets saved
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var connections : Array[Dictionary]

func _init() -> void:
	if nodes.size()==0:
		var first_node = AccessPointNode.new()
		first_node.resource_name = "start_node"
		add_node(first_node)

func add_node(node:BehaviorNode):
	nodes.append(node)

func remove_node(node:BehaviorNode):
	var index : int = -1
	for i in nodes.size():
		if nodes[i]==node: 
			index = i
	if index == -1:
		push_error("Couldn't find node %s"%node)
		return
	nodes.remove_at(index)

func add_connection(connection:Dictionary):
	connections.append(connection)

func remove_connection(connection:Dictionary):
	var index : int = -1
	for i in connections.size():
		if connections[i]==connection: 
			index = i
	if index == -1:
		push_error("Couldn't find connection %s"%connection)
		return
	connections.remove_at(index)

func get_starting_nodes() ->Array[BehaviorNode]:
	var ret : Array[BehaviorNode] = []
	for node in nodes:
		if node.node_category == "access_point_node": ret.append(node)
	return ret

func get_starting_node(name:StringName)->BehaviorNode:
	for node in nodes:
		if node.resource_name == name: return node
	push_error("Couldn't find node \"%s\""%name)
	return null

func get_starting_nodes_names() ->PackedStringArray:
	var ret : PackedStringArray = []
	for node in nodes:
		if node.node_category == "access_point_node": ret.append(node.resource_name)
	return ret

func get_node(name:StringName)->BehaviorNode:
	for node in nodes:
		if node.resource_name==name:
			return node
	push_error("node %s not found"%name)
	return
