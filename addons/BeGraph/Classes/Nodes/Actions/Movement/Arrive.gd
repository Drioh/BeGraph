@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Arrive"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Like 'Seek', but decelerates: moves {node} towards {target} (Node, Vector2 or Vector3) at {speed} until it is closer than {slowing_radius}, then the speed drops proportionally to the remaining distance (never below {min_speed}).\n\nReturns RUNNING while moving and SUCCESS once closer than {stop_distance}; fails if {node} or {target} can't be resolved."

var _node : Node

func set_instruction() -> String:
	return "Arrive at {target} with {node} (speed {speed}, slowing radius {slowing_radius})"

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

	var distance : float = _get_position(_node).distance_to(destination)
	if distance <= maxf(get("stop_distance"), 0.001):
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	var speed : float = get("speed")
	var slowing_radius : float = get("slowing_radius")
	var desired : float = speed
	if slowing_radius > 0.0 and distance < slowing_radius:
		desired = maxf(speed * distance / slowing_radius, minf(float(get("min_speed")), speed))

	_step_towards(_node, destination, desired * delta)
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("target", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("speed", float(150.0))
	_add_behavior_property("slowing_radius", float(150.0))
	_add_behavior_property("min_speed", float(10.0))
	_add_behavior_property("stop_distance", float(2.0))

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
