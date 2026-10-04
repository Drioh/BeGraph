@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Position"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Instantly moves {node} (Node2D/3D) to {position} (a Node, Vector2 or Vector3): a teleport.\n\nIf {position} is a Node, its global position is used. If it is a vector, {global_space} chooses between global and local (parent-relative) coordinates. Vector2 sets only X/Y on a 3D node and a Vector3 ignores Z on a 2D one.\n\nSucceeds once applied; fails if {node} or {position} can't be resolved."

func set_instruction() -> String:
	return "Teleport {node} to {position}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not (target is Node2D or target is Node3D):
		push_error("\"%s\" couldn't resolve a Node2D/Node3D" % resource_name)
		return Status.FAILURE

	var value : Variant = get("position")
	var point : Variant = _resolve_position(value)
	if point == null:
		push_error("\"%s\" couldn't resolve position" % resource_name)
		return Status.FAILURE
	var destination : Vector3 = point

	var is_vector : bool = value is Vector2 or value is Vector3
	if get("global_space") or not is_vector:
		_set_position(target, destination)
	elif target is Node2D:
		target.position = Vector2(destination.x, destination.y)
	else:
		target.position = destination

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("position", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("global_space", true)

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
