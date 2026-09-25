@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Move"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves {node} towards {destination} (Node, Vector2 or Vector3) at {speed} or over {duration}, depending on {mode}. \n\nCan re-evaluate {destination} every frame ({calculate_destination_each_frame}) in order to have dynamic targets and optionally waits on arrival. \n\nReturns RUNNING while moving and SUCCESS on arrival; fails if {node} or {destination} can't be resolved."

enum Mode { SPEED, DURATION }

var _elapsed : float = 0.0
var _waiting : bool = false
var _wait_elapsed : float = 0.0

var _node : Node
var _duration : float
var _destination : Variant
var wait_time : float


func set_instruction() -> String:
	return "Move {node} to {destination} ({mode})"

func tick(delta:float) -> Status:
	if dirty:
		_node = _resolve_node(get("node"))
		_duration = get("duration")
		_destination = _resolve_node(get("destination"))
		wait_time = get("time_to_wait_upon_reaching_destination")
		
		if _node == null:
			push_error("\"%s\" couldn't resolve node to move" % resource_name)
			return Status.FAILURE
		if _node == null:
			push_error("\"%s\" couldn't resolve destination to move towards" % resource_name)
			return Status.FAILURE
	dirty=false
	
	var now : int = Time.get_ticks_msec()
	
	if _waiting:
		_wait_elapsed += delta
		if _wait_elapsed < wait_time:
			return Status.RUNNING
		_waiting = false
		_wait_elapsed = 0.0
		tick_next(delta)
		return Status.SUCCESS
	
	_elapsed += delta
	
	if(get("calculate_destination_each_frame")):
		_destination = _resolve_node(get("destination"))

	var reached : bool = _move_towards_destination(delta)

	if not reached:
		return Status.RUNNING

	_elapsed = 0.0
	
	if wait_time > 0.0:
		_waiting = true
		_wait_elapsed = 0.0
		return Status.RUNNING
	
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("destination", null ,PROPERTY_HINT_NONE,"","","",PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Speed,Duration")
	_add_behavior_property("speed", float(100.0))
	_add_behavior_property("duration", float(1.0))
	_add_behavior_property("calculate_destination_each_frame", false)
	_add_behavior_property("time_to_wait_upon_reaching_destination", float(0))

func _move_towards_destination(delta: float) -> bool:
	var distance_remaining : float = _node.global_position.distance_to(_destination)
	
	if distance_remaining <= 0.001:
		_node.global_position = _destination
		return true
	
	var move_amount : float
	
	if get("mode") == Mode.SPEED:
		move_amount = get("speed") * delta
	else:
		var remaining_time : float = _duration - _elapsed
		if remaining_time <= 0.0:
			_node.global_position = _destination
			return true
		move_amount = (distance_remaining / remaining_time) * delta
	
	_node.global_position = _node.global_position.move_toward(_destination, move_amount)
	return _node.global_position.distance_to(_destination) <= 0.001
