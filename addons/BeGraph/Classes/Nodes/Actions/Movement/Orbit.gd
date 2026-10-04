@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Orbit"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Makes {node} (Node2D/3D) circle around {center} (Node, Vector2 or Vector3) at {radius} units, turning {angular_speed} degrees/second in the given {direction}. The center is re-read every tick, so it can be a moving Node. In 3D the rotation happens around the vertical (Y) axis.\n\nIf the node isn't at {radius} yet, the distance is adjusted at {radius_speed} units/second while orbiting.\n\nReturns RUNNING forever, or, if {duration} is greater than 0, ticks its successor and returns SUCCESS after that many seconds. Fails if {node} or {center} can't be resolved."

enum Direction { CLOCKWISE, COUNTERCLOCKWISE }

var _node : Node
var _elapsed : float = 0.0

func set_instruction() -> String:
	return "Orbit {node} around {center} (radius {radius}, {angular_speed} deg/s)"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_node):
		_node = _resolve_node(get("node"))
		if _node == null:
			push_error("\"%s\" couldn't resolve node to move" % resource_name)
			return Status.FAILURE
		_elapsed = 0.0
		dirty = false

	var point : Variant = _resolve_position(get("center"))
	if point == null:
		push_error("\"%s\" couldn't resolve center" % resource_name)
		return Status.FAILURE
	var center : Vector3 = point

	var is_3d : bool = _node is Node3D
	var offset : Vector3 = _get_position(_node) - center
	if offset.length() < 0.001:
		offset = Vector3.RIGHT

	var new_length : float = move_toward(offset.length(), get("radius"), float(get("radius_speed")) * delta)
	offset = offset.normalized() * new_length

	# Positive angles turn clockwise on screen in 2D (y points down) but counterclockwise seen from above in 3D.
	var turn : float = 1.0 if get("direction") == Direction.CLOCKWISE else -1.0
	if is_3d:
		turn = -turn
	var axis : Vector3 = Vector3.UP if is_3d else Vector3.BACK
	offset = offset.rotated(axis, deg_to_rad(get("angular_speed")) * turn * delta)
	_set_position(_node, center + offset)

	var duration : float = get("duration")
	if duration > 0.0:
		_elapsed += delta
		if _elapsed >= duration:
			dirty = true
			tick_next(delta)
			return Status.SUCCESS
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("center", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("radius", float(150.0))
	_add_behavior_property("angular_speed", float(90.0))
	_add_behavior_property("direction", 0, PROPERTY_HINT_ENUM, "Clockwise,Counterclockwise")
	_add_behavior_property("radius_speed", float(300.0))
	_add_behavior_property("duration", float(0.0))

#region Helpers (self-contained copies, no external dependency)

## Resolves [param value] (a [NodePath], a [Node], a [Vector2] or a [Vector3]) to a global position as [Vector3]. Returns [code]null[/code] if it can't be resolved.
func _resolve_position(value: Variant) -> Variant:
	if value is Vector3:
		return value
	if value is Vector2:
		return Vector3(value.x, value.y, 0.0)
	var n : Node = _resolve_node(value)
	if n == null:
		return null
	return _get_position(n)

## Global position of [param n] (Node2D or Node3D) as [Vector3]; z is 0 for 2D nodes.
func _get_position(n: Node) -> Vector3:
	if n is Node2D:
		var p : Vector2 = n.global_position
		return Vector3(p.x, p.y, 0.0)
	if n is Node3D:
		return n.global_position
	return Vector3.ZERO

## Sets the global position of [param n] (Node2D ignores z).
func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D:
		n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D:
		n.global_position = pos

#endregion
