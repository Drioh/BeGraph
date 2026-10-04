@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Flee"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves {node} (Node2D/3D) directly away from {target} (Node, Vector2 or Vector3) at {speed} units/second. The target is re-read every tick.\n\nReturns RUNNING while closer than {safe_distance} and SUCCESS once that distance is reached; fails if {node} or {target} can't be resolved.\n\nIn 3D the direction also includes the vertical component."

var _node : Node

func set_instruction() -> String:
	return "Flee from {target} with {node} until {safe_distance} away"

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
	var threat : Vector3 = point

	var current : Vector3 = _get_position(_node)
	var away : Vector3 = current - threat
	var distance : float = away.length()
	if distance >= float(get("safe_distance")):
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	var direction : Vector3 = away / distance if distance > 0.0001 else _random_direction(_node is Node3D)
	_set_position(_node, current + direction * float(get("speed")) * delta)
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("target", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("speed", float(150.0))
	_add_behavior_property("safe_distance", float(300.0))

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
