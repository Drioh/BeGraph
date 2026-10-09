@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Rotate"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { TO_ANGLE, TOWARDS_NODE, CONTINUOUS_SPIN }
enum SpeedMode { SPEED, DURATION }
enum Direction { SHORTEST, CLOCKWISE, COUNTERCLOCKWISE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"ToAngle,TowardsNode,ContinuousSpin") var mode : Mode = Mode.TO_ANGLE
@export_custom(BG.HINT_NONE, BG.PROPERTY) var target_angle : float = 0.0
@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var target_node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"X,Y,Z") var axis_3d : int = 1
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Speed,Duration") var speed_mode : SpeedMode = SpeedMode.SPEED
@export_custom(BG.HINT_NONE, BG.PROPERTY) var angular_speed : float = 90.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 1.0
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Shortest,Clockwise,Counterclockwise") var direction : Direction = Direction.SHORTEST
@export_custom(BG.HINT_NONE, BG.PROPERTY) var recalculate_target_each_frame : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var loop : bool = false

var _node_ref : Node = null
var _target_node_ref : Node = null
var _is_3d : bool = false
var _target_rot : float = 0.0
var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node to rotate")
		return
		
	_is_3d = _node_ref is Node3D
	if (eval(&"mode") as Mode) == Mode.TOWARDS_NODE:
		_target_node_ref = _resolve_node(eval(&"target_node"))
		if _target_node_ref == null:
			abort("couldn't resolve target node to face")
			return
			
	_target_rot = _calculate_target_rotation()

func tick(delta: float) -> Status:
	if (eval(&"mode") as Mode) == Mode.CONTINUOUS_SPIN:
		return _tick_spin(delta)
	return _tick_towards(delta)

func _tick_spin(delta: float) -> Status:
	var turn : float = -1.0 if (eval(&"direction") as Direction) == Direction.COUNTERCLOCKWISE else 1.0
	_set_rotation(_get_rotation() + deg_to_rad(eval(&"angular_speed") as float) * turn * delta)
	
	if (eval(&"speed_mode") as SpeedMode) == SpeedMode.DURATION:
		_elapsed += delta
		if _elapsed >= (eval(&"duration") as float) and not eval(&"loop"):
			_elapsed = 0.0
			return tick_next(delta)
			
	return Status.RUNNING

func _tick_towards(delta: float) -> Status:
	_elapsed += delta
	if eval(&"recalculate_target_each_frame") and (eval(&"mode") as Mode) == Mode.TOWARDS_NODE:
		_target_rot = _calculate_target_rotation()
		
	var current : float = _get_rotation()
	var diff : float = wrapf(_target_rot - current, -PI, PI)
	
	if absf(diff) <= 0.0005:
		_set_rotation(_target_rot)
		return _finish(delta)
		
	var step : float = 0.0
	if (eval(&"speed_mode") as SpeedMode) == SpeedMode.SPEED:
		var max_step : float = deg_to_rad(eval(&"angular_speed") as float) * delta
		step = clampf(diff, -max_step, max_step)
	else:
		var rem_t : float = (eval(&"duration") as float) - _elapsed
		if rem_t <= 0.0:
			_set_rotation(_target_rot)
			return _finish(delta)
		step = (diff / rem_t) * delta
		
	_set_rotation(current + step)
	return Status.RUNNING

func _finish(delta: float) -> Status:
	_elapsed = 0.0
	if eval(&"loop"):
		return Status.RUNNING
	return tick_next(delta)

func _calculate_target_rotation() -> float:
	match eval(&"mode") as Mode:
		Mode.TO_ANGLE: return deg_to_rad(eval(&"target_angle") as float)
		Mode.TOWARDS_NODE:
			if not _is_3d:
				return _node_ref.global_position.angle_to_point(_target_node_ref.global_position)
			var d : Vector3 = _target_node_ref.global_position - _node_ref.global_position
			match eval(&"axis_3d") as int:
				0: return atan2(d.y, d.z)
				2: return atan2(d.y, d.x)
				_: return atan2(d.x, d.z)
	return _get_rotation()

func _get_rotation() -> float:
	return _node_ref.rotation[eval(&"axis_3d") as int] if _is_3d else _node_ref.rotation

func _set_rotation(angle: float) -> void:
	if _is_3d:
		var r : Vector3 = _node_ref.rotation
		r[eval(&"axis_3d") as int] = angle
		_node_ref.rotation = r
	else:
		_node_ref.rotation = angle

func set_instruction() -> String: return "Rotate {node} ({mode}, axis {axis_3d})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
