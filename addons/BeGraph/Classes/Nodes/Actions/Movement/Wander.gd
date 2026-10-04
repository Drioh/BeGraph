@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wander"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Makes {node} (Node2D/3D) walk to random points within {radius} units at {speed}, pausing {wait_time}s at each one. In 3D the points are picked on the horizontal (XZ) plane.\n\nIf {around_start} is true the points are picked around the position {node} had when the wander started, otherwise around its current position.\n\nKeeps returning RUNNING; if {points_to_visit} is greater than 0, ticks its successor and returns SUCCESS after that many points (0 = wander forever). Fails if {node} can't be resolved."

var _node : Node
var _origin : Vector3 = Vector3.ZERO
var _destination : Vector3 = Vector3.ZERO
var _has_destination : bool = false
var _waiting : bool = false
var _wait_left : float = 0.0
var _visited : int = 0

func set_instruction() -> String:
	return "Wander {node} within {radius} at speed {speed}"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_node):
		_node = _resolve_node(get("node"))
		if _node == null:
			push_error("\"%s\" couldn't resolve node to move" % resource_name)
			return Status.FAILURE
		_origin = _get_position(_node)
		_has_destination = false
		_waiting = false
		_visited = 0
		dirty = false

	if _waiting:
		_wait_left -= delta
		if _wait_left > 0.0:
			return Status.RUNNING
		_waiting = false

	if not _has_destination:
		_destination = _pick_destination()
		_has_destination = true

	var remaining : float = _step_towards(_node, _destination, float(get("speed")) * delta)
	if remaining > 0.0:
		return Status.RUNNING

	_has_destination = false
	_visited += 1
	var limit : int = get("points_to_visit")
	if limit > 0 and _visited >= limit:
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	_wait_left = get("wait_time")
	_waiting = _wait_left > 0.0
	return Status.RUNNING

func _pick_destination() -> Vector3:
	var center : Vector3 = _origin if get("around_start") else _get_position(_node)
	var offset : Vector3 = _random_direction(_node is Node3D) * sqrt(randf()) * float(get("radius"))
	return center + offset

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("radius", float(200.0))
	_add_behavior_property("speed", float(80.0))
	_add_behavior_property("wait_time", float(1.0))
	_add_behavior_property("around_start", true)
	_add_behavior_property("points_to_visit", int(0))

#region Helpers (self-contained copies, no external dependency)

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

## Random unit direction: on the XY plane for 2D, on the XZ plane for 3D.
func _random_direction(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	if in_3d:
		return Vector3(cos(angle), 0.0, sin(angle))
	return Vector3(cos(angle), sin(angle), 0.0)

#endregion
