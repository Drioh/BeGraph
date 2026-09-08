@tool
class_name BehaviorAgent
extends Node

enum ProcessThread { IDLE, PHYSICS, MANUAL }
enum Status { SUCCESS, FAILURE, RUNNING }

@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_process_flags()

@export var behavior_graph: BehaviorGraph:
	set(value):
		if behavior_graph == value:
			return
		behavior_graph = value
		_starting_point_idx = 0
		_select_starting_node(_starting_point_idx)
		notify_property_list_changed.call_deferred()

@export var graph_process_mode: ProcessThread = ProcessThread.IDLE:
	set(value):
		graph_process_mode = value
		if graph_process_mode == ProcessThread.MANUAL:
			enabled = false
		_update_process_flags()

var _starting_point_idx: int = 0
var starting_node: BehaviorNode = null


func _update_process_flags() -> void:
	set_physics_process(enabled and graph_process_mode == ProcessThread.PHYSICS)
	set_process(enabled and graph_process_mode == ProcessThread.IDLE)


func _get_property_list() -> Array[Dictionary]:
	var ret: Array[Dictionary] = []
	if behavior_graph != null:
		var names := behavior_graph.get_starting_nodes_names()
		var hint_string := ""
		hint_string = ",".join(names)

		ret.append({
			"name": "starting_point",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": hint_string,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	return ret


func _get(property: StringName) -> Variant:
	if property == "starting_point":
		return _starting_point_idx
	return null


func _set(property: StringName, value: Variant) -> bool:
	if property == "starting_point":
		_starting_point_idx = value
		_select_starting_node(_starting_point_idx)
		return true
	return false


func _ready() -> void:
	if not Engine.is_editor_hint():
		if behavior_graph == null:
			push_error("Behavior Graph not set for Behavior Agent %s" % self)
			process_mode = Node.PROCESS_MODE_DISABLED
			return
		if starting_node == null:
			push_error("Starting Node not set for Behavior Agent %s" % self)
			process_mode = Node.PROCESS_MODE_DISABLED
			return


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if starting_node != null:
			starting_node.tick()


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if starting_node != null:
			starting_node.tick()


func tick() -> void:
	if enabled and starting_node != null:
		starting_node.tick()


func _select_starting_node(index: int) -> void:
	if behavior_graph == null:
		starting_node = null
		return
		
	var names := behavior_graph.get_starting_nodes_names()
	if names == null:
		starting_node = null
		return
		
	if index >= 0 and index < names.size():
		starting_node = behavior_graph.get_starting_node(names[index])
	else:
		starting_node = null
