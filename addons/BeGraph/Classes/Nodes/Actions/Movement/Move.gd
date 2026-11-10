@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Move"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves {node} towards {destination} (Node, Vector2 or Vector3) at {speed} or over {duration}, depending on {mode}. \n\nCan re-evaluate {destination} every frame ({calculate_destination_each_frame}) in order to have dynamic targets and optionally waits on arrival. \n\nReturns RUNNING while moving and SUCCESS on arrival; fails if {node} or {destination} can't be resolved."

enum Mode { SPEED, DURATION }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var destination : Variant = null
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY + "Speed,Duration",) var mode : Mode = Mode.SPEED
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var moving_target : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var changing_speed : bool = false

var _elapsed : float = 0.0

var _node : Node
var _destination : Variant
var _mode : Mode
var _speed : float
var _duration : float
var _moving_target : bool
var _changing_speed : bool

func on_start() -> void:
	_elapsed = 0.0
	
	_mode = eval(&"mode") as Mode
	_speed = eval(&"speed") as float
	_duration = eval(&"duration") as float
	
	_moving_target = eval(&"moving_target") as bool
	_changing_speed = eval(&"changing_speed") as bool
	
	_node = eval(&"node", true)
	_destination = _resolve_destination_pos(eval(&"destination"))

func tick(delta: float) -> Status:
	if _node == null or not is_instance_valid(_node):
		return abort("couldn't resolve node to move")
	
	if _moving_target:
		_destination = _resolve_destination_pos(eval(&"destination"))
	if _destination == null:
		return abort("couldn't resolve destination to move towards")
	
	_elapsed += delta
	var reached : bool = _move_towards_destination(delta)
	if not reached: return Status.RUNNING

	return Status.SUCCESS

func on_end(_status: Status) -> void:
	_node = null
	_elapsed = 0.0

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"destination"):
		_destination = _resolve_destination_pos(eval(&"destination"))

func _resolve_destination_pos(raw_dest: Variant) -> Variant:
	var is_coord : bool = raw_dest is Vector2 or raw_dest is Vector3
	return raw_dest if is_coord else _resolve_node(raw_dest).global_position

func _move_towards_destination(delta: float) -> bool:
	var dest_pos : Variant = _destination
	if dest_pos is Node2D or dest_pos is Node3D:
		dest_pos = dest_pos.global_position

	var distance_remaining : float = _node.global_position.distance_to(dest_pos)
	if distance_remaining <= 0.001:
		_node.global_position = dest_pos
		return true
	
	var move_amount : float
	if _mode == Mode.SPEED:
		if _changing_speed:
			_speed = eval(&"speed") as float
		move_amount = _speed * delta
	else:
		var remaining_time : float = _duration - _elapsed
		if remaining_time <= 0.0:
			_node.global_position = dest_pos
			return true
		move_amount = (distance_remaining / remaining_time) * delta
	
	_node.global_position = _node.global_position.move_toward(dest_pos, move_amount)
	return _node.global_position.distance_to(dest_pos) <= 0.001

func set_instruction() -> String:
	return "Move {node} to {destination} ({mode})"

func set_node_category() -> String: 
	return "action_node"

func set_input() -> bool: 
	return true

func set_output() -> bool: 
	return true

func set_allows_multiple_outputs() -> bool: 
	return false
