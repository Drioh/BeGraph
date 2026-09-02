@tool
class_name BehaviorGraph
extends Resource

##If set to [code]true[/code], this graph gets triggered as soon as the scene starts
@export var activate_on_start : bool = false
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

##BehaviorNodes contained in this graph
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY) var nodes : Dictionary = {
	&"": {
		"node": AccessPointNode.new(),
		"position": Vector2(0,0),
		"is_starting_point" : false,
	}
	}

##Used for saving purposes, this variable contains a copy of [param connections] from the graph edit. This value gets its value when a graph gets saved
@export var connections : Array
