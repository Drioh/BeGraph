@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Seek"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves {node} (Node2D/3D) in a straight line towards {target} (Node, Vector2 or Vector3) at {speed} units/second. The target position is re-read every tick, so a Node (or a blackboard variable holding one) is followed live.\n\nReturns RUNNING while moving and SUCCESS once closer than {stop_distance}; fails if {node} or {target} can't be resolved."

var _node : Node

func set_instruction() -> String:
	return "Seek {target} with {node} at speed {speed}"

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
	var destination : Vector3 = point

	var stop_distance : float = maxf(get("stop_distance"), 0.001)
	if _get_position(_node).distance_to(destination) <= stop_distance:
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	_step_towards(_node, destination, float(get("speed")) * delta)
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("target", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("speed", float(150.0))
	_add_behavior_property("stop_distance", float(5.0))

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

## Moves [param n] towards [param destination] by at most [param max_step]. Returns the distance still to cover (0 when it arrived).
func _step_towards(n: Node, destination: Vector3, max_step: float) -> float:
	var current : Vector3 = _get_position(n)
	var remaining : float = current.distance_to(destination)
	if remaining <= max_step or remaining <= 0.0001:
		_set_position(n, destination)
		return 0.0
	_set_position(n, current.move_toward(destination, max_step))
	return remaining - max_step

#endregion
