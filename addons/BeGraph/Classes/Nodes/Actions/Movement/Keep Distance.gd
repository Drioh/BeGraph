@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Keep Distance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Keeps {node} (Node2D/3D) between {min_distance} and {max_distance} units from {target} (Node, Vector2 or Vector3): moves away when it is too close and closer when it is too far, at {speed} units/second, never overshooting the allowed band. Useful for ranged enemies.\n\nIf {finish_when_in_range} is false it keeps returning RUNNING (it keeps adjusting forever); if true it ticks its successor and returns SUCCESS as soon as the distance is inside the band.\n\nFails if {node} or {target} can't be resolved."

var _node : Node

func set_instruction() -> String:
	return "Keep {node} between {min_distance} and {max_distance} from {target}"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_node):
		_node = _resolve_node(get("node"))
		if _node == null:
			push_error("\"%s\" couldn't resolve node to move" % resource_name)
			return Status.FAILURE
		dirty = false

	var point : Variant = _resolve_position(get("target"))
	if point == null:
		push_error("\"%s\" couldn't resolve target" % resource_name)
		return Status.FAILURE
	var anchor : Vector3 = point

	var current : Vector3 = _get_position(_node)
	var away : Vector3 = current - anchor
	var distance : float = away.length()
	var min_distance : float = get("min_distance")
	var max_distance : float = maxf(get("max_distance"), min_distance)
	var step : float = float(get("speed")) * delta

	var direction : Vector3 = away / distance if distance > 0.0001 else _random_direction(_node is Node3D)
	if distance < min_distance:
		_set_position(_node, current + direction * minf(step, min_distance - distance))
	elif distance > max_distance:
		_set_position(_node, current - direction * minf(step, distance - max_distance))
	elif get("finish_when_in_range"):
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
	_add_behavior_property("target", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("min_distance", float(150.0))
	_add_behavior_property("max_distance", float(250.0))
	_add_behavior_property("speed", float(100.0))
	_add_behavior_property("finish_when_in_range", false)

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

## Random unit direction: on the XY plane for 2D, on the XZ plane for 3D.
func _random_direction(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	if in_3d:
		return Vector3(cos(angle), 0.0, sin(angle))
	return Vector3(cos(angle), sin(angle), 0.0)

#endregion
