@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Rotate"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Rotation of a Node2D or Node3D {node}.\n\nDepending on {mode}:\n - turns {node} to a fixed {target_angle}° (ToAngle);\n - makes it face {target_node} (TowardsNode; tracked live every frame when {recalculate_target_each_frame} is enabled);\n - spins it forever (ContinuousSpin).\n\nFor Node3D, rotation happens around {axis_3d} (X, Y or Z).\n\nNode2D always rotates around Z and ignores {axis_3d}.\n\n{speed_mode} chooses whether turning is paced by {angular_speed}°/s or completes over a fixed {duration}s. {direction} forces the shortest path (or a specific clockwise/counterclockwise turn) when seeking a target angle, and also picks which way ContinuousSpin turns.\n\nReturns RUNNING while turning, SUCCESS on arrival (unless {loop} is enabled, which keeps it running/tracking forever instead); fails if {node} (or {target_node}, in TowardsNode mode) can't be resolved."

enum Mode { TO_ANGLE, TOWARDS_NODE, CONTINUOUS_SPIN }
enum SpeedMode { SPEED, DURATION }
enum Direction { SHORTEST, CLOCKWISE, COUNTERCLOCKWISE }

var _node : Node = null
var _target_node : Node = null
var _is_3d : bool = false

var _target_rotation : float = 0.0
var _start_time : int = -1
var _last_tick_time : int = -1

func set_instruction() -> String:
	return "Rotate {node} ({mode}, axis {axis_3d}) to {target_angle}° / facing {target_node} — {speed_mode}: {angular_speed}°/s or {duration}s ({direction})"

func tick() -> Status:
	if dirty:
		_node = _resolve_node(get("node"))
		if _node == null:
			push_error("\"%s\" couldn't resolve node to rotate" % resource_name)
			return Status.FAILURE
		_is_3d = _node is Node3D

		if get("mode") == Mode.TOWARDS_NODE:
			_target_node = _resolve_node(get("target_node"))
			if _target_node == null:
				push_error("\"%s\" couldn't resolve target node to face" % resource_name)
				return Status.FAILURE

		_start_time = -1
		_last_tick_time = Time.get_ticks_msec()
		_target_rotation = _calculate_target_rotation()
		dirty = false

	if get("mode") == Mode.CONTINUOUS_SPIN:
		return _tick_continuous_spin()
	return _tick_towards_target()

func _tick_continuous_spin() -> Status:
	var now : int = Time.get_ticks_msec()
	var delta : float = (now - _last_tick_time) / 1000.0
	_last_tick_time = now

	_rotate_by(deg_to_rad(get("angular_speed")) * _direction_sign() * delta)

	if get("speed_mode") == SpeedMode.DURATION:
		if _start_time == -1:
			_start_time = now
		var elapsed : float = (now - _start_time) / 1000.0
		if elapsed >= get("duration") and not get("loop"):
			_start_time = -1
			dirty = true
			return Status.SUCCESS

	return Status.RUNNING

func _tick_towards_target() -> Status:
	var now : int = Time.get_ticks_msec()
	var delta : float = (now - _last_tick_time) / 1000.0
	_last_tick_time = now

	if _start_time == -1:
		_start_time = now

	if get("recalculate_target_each_frame") and get("mode") == Mode.TOWARDS_NODE:
		_target_rotation = _calculate_target_rotation()

	var current : float = _get_rotation()
	var remaining : float = _apply_direction(wrapf(_target_rotation - current, -PI, PI))

	if abs(remaining) <= 0.0005:
		_set_rotation(_target_rotation)
		return _finish()

	var step : float
	if get("speed_mode") == SpeedMode.SPEED:
		var max_step : float = deg_to_rad(get("angular_speed")) * delta
		step = clamp(remaining, -max_step, max_step)
	else:
		var elapsed : float = (now - _start_time) / 1000.0
		var remaining_time : float = get("duration") - elapsed
		if remaining_time <= 0.0:
			_set_rotation(_target_rotation)
			return _finish()
		step = (remaining / remaining_time) * delta

	_set_rotation(current + step)
	return Status.RUNNING

func _finish() -> Status:
	_start_time = -1
	dirty = true
	if get("loop"):
		return Status.RUNNING
	return Status.SUCCESS

func _calculate_target_rotation() -> float:
	match get("mode"):
		Mode.TO_ANGLE:
			return deg_to_rad(get("target_angle"))
		Mode.TOWARDS_NODE:
			return _angle_to_target()
		_:
			return _get_rotation()

func _angle_to_target() -> float:
	if not _is_3d:
		return _node.global_position.angle_to_point(_target_node.global_position)

	var delta : Vector3 = _target_node.global_position - _node.global_position
	match get("axis_3d"):
		0: return atan2(delta.y, delta.z)
		2: return atan2(delta.y, delta.x)
		_: return atan2(delta.x, delta.z)

func _get_rotation() -> float:
	if _is_3d:
		return _node.rotation[get("axis_3d")]
	return _node.rotation

func _set_rotation(angle : float) -> void:
	if _is_3d:
		var r : Vector3 = _node.rotation
		r[get("axis_3d")] = angle
		_node.rotation = r
	else:
		_node.rotation = angle

func _rotate_by(delta_angle : float) -> void:
	_set_rotation(_get_rotation() + delta_angle)

func _direction_sign() -> float:
	if get("direction") == Direction.COUNTERCLOCKWISE:
		return -1.0
	return 1.0

func _apply_direction(diff : float) -> float:
	match get("direction"):
		Direction.CLOCKWISE:
			return diff if diff >= 0.0 else diff + TAU
		Direction.COUNTERCLOCKWISE:
			return diff if diff <= 0.0 else diff - TAU
		_:
			return diff

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "ToAngle,TowardsNode,ContinuousSpin")
	_add_behavior_property("target_angle", float(0.0))
	_add_behavior_property("target_node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("axis_3d", 1, PROPERTY_HINT_ENUM, "X,Y,Z")
	_add_behavior_property("speed_mode", 0, PROPERTY_HINT_ENUM, "Speed,Duration")
	_add_behavior_property("angular_speed", float(90.0))
	_add_behavior_property("duration", float(1.0))
	_add_behavior_property("direction", 0, PROPERTY_HINT_ENUM, "Shortest,Clockwise,Counterclockwise")
	_add_behavior_property("recalculate_target_each_frame", false)
	_add_behavior_property("loop", false)
