@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Patrol"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves {node} back and forth between {points} (Arrays of Nodes or Vector2s/Vecgor3s), one at a time, at {speed} or over {duration} depending on {mode}. \n\nOptionally pauses {time_to_wait_upon_reaching_destination}s at each stop and loops via {loop}. \n\nReturns RUNNING while moving, SUCCESS at the end of a non-looping patrol, FAILURE if {node} or the points can't be resolved."

enum Mode { SPEED, DURATION }

var _index : int = 0
var current_destination
var _start_time : int = -1
var _last_tick_time : int = -1
var _waiting : bool = false
var _wait_start_time : int = -1

var _node : Node
var _points : Array = []
var _points_nodepaths
var duration : float
var wait_time : float

var first_time : bool = true

func set_instruction() -> String:
	return "Patrol {node} between {points}(mode: {mode})"

func tick() -> Status:
	if first_time:
		_points_nodepaths= get("points")
		_node = _resolve_node(get("node"))
		duration = get("duration")
		wait_time = get("time_to_wait_upon_reaching_destination")
		
		if _node == null:
			push_error("\"%s\" couldn't resolve node to move" % resource_name)
			return Status.FAILURE
		for p in _points_nodepaths:
			_points.append(_resolve_node(p))
		if _points.is_empty():
			return Status.FAILURE
		calculate_current_destination()
	first_time=false
	
	var now : int = Time.get_ticks_msec()
	
	if _waiting:
		if (now - _wait_start_time) / 1000.0 < wait_time:
			return Status.RUNNING
		_waiting = false
		_wait_start_time = -1
		return _advance_to_next_point()
	
	if _start_time == -1:
		_start_time = now
		_last_tick_time = now
	
	var delta : float = (now - _last_tick_time) / 1000.0
	_last_tick_time = now
	
	if(get("calculate_destination_each_frame")):
		calculate_current_destination()

	var reached : bool = _move_towards_destination(delta, now)

	if not reached:
		return Status.RUNNING

	_start_time = -1
	
	if wait_time > 0.0:
		_waiting = true
		_wait_start_time = now
		return Status.RUNNING
	
	return _advance_to_next_point()

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""),PROPERTY_HINT_NODE_TYPE,"Node2D,Node3D","","",PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("points", [])
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Speed,Duration")
	_add_behavior_property("speed", float(100.0))
	_add_behavior_property("duration", float(1.0))
	_add_behavior_property("loop", true)
	_add_behavior_property("calculate_destination_each_frame", false)
	_add_behavior_property("time_to_wait_upon_reaching_destination", float(0))

func _advance_to_next_point() -> Status:
	_index += 1
	
	if _index >= _points.size():
		if !get("loop"):
			_index = _points.size() - 1
			return Status.SUCCESS
		_index = 0
	calculate_current_destination()
	return Status.RUNNING

func _move_towards_destination(delta: float, now: int) -> bool:
	var distance_remaining : float = _node.global_position.distance_to(current_destination)
	
	if distance_remaining <= 0.001:
		_node.global_position = current_destination
		return true
	
	var move_amount : float
	
	if get("mode") == Mode.SPEED:
		move_amount = get("speed") * delta
	else:
		var elapsed : float = (now - _start_time) / 1000.0
		var remaining_time : float = duration - elapsed
		if remaining_time <= 0.0:
			_node.global_position = current_destination
			return true
		move_amount = (distance_remaining / remaining_time) * delta
	
	_node.global_position = _node.global_position.move_toward(current_destination, move_amount)
	return _node.global_position.distance_to(current_destination) <= 0.001

func calculate_current_destination():
	if _points[_index] is Node3D \
		or _points[_index] is Node2D:
			current_destination= _points[_index].global_position
	elif _points[_index] is Vector2 \
		or _points[_index] is Vector3:
		current_destination= _points[_index]
