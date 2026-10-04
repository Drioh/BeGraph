@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Pursue"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Chases {target} (a moving Node2D/3D) with {node} at {speed} units/second, aiming where the target is going to be instead of where it is: the target's velocity is estimated from its movement between ticks and projected forward by the time needed to reach it (at most {max_prediction}s).\n\nReturns RUNNING while chasing and SUCCESS once closer than {stop_distance}; fails if {node} or {target} can't be resolved."

var _node : Node
var _last_target_position : Vector3 = Vector3.ZERO
var _has_last_position : bool = false

func set_instruction() -> String:
	return "Pursue {target} with {node} at speed {speed}"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_node):
		_node = _resolve_node(get("node"))
		if _node == null:
			push_error("\"%s\" couldn't resolve node to move" % resource_name)
			return Status.FAILURE
		_has_last_position = false
		dirty = false

	var target : Node = _resolve_node(get("target"))
	if target == null:
		push_error("\"%s\" couldn't resolve target (a Node is required)" % resource_name)
		return Status.FAILURE

	var target_position : Vector3 = _get_position(target)
	var target_velocity : Vector3 = Vector3.ZERO
	if _has_last_position and delta > 0.0:
		target_velocity = (target_position - _last_target_position) / delta
	_last_target_position = target_position
	_has_last_position = true

	var current : Vector3 = _get_position(_node)
	var distance : float = current.distance_to(target_position)
	if distance <= maxf(get("stop_distance"), 0.001):
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	var speed : float = get("speed")
	var lookahead : float = clampf(distance / maxf(speed, 0.001), 0.0, get("max_prediction"))
	var predicted : Vector3 = target_position + target_velocity * lookahead

	_step_towards(_node, predicted, speed * delta)
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("target", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("speed", float(150.0))
	_add_behavior_property("max_prediction", float(1.0))
	_add_behavior_property("stop_distance", float(5.0))

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

#endregion
