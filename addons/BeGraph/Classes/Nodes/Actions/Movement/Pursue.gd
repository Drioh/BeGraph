@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Pursue"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var target : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 150.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var max_prediction : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var stop_distance : float = 5.0

var _node_ref : Node
var _last_target_pos : Vector3 = Vector3.ZERO
var _has_last_pos : bool = false

func on_start() -> void:
	_has_last_pos = false
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node")

func tick(delta: float) -> Status:
	var target_node := _resolve_node(eval(&"target"))
	if target_node == null:
		return abort("couldn't resolve target node")
		
	var target_pos : Vector3 = _get_position(target_node)
	var target_vel : Vector3 = Vector3.ZERO
	if _has_last_pos and delta > 0.0:
		target_vel = (target_pos - _last_target_pos) / delta
	_last_target_pos = target_pos
	_has_last_pos = true
	
	var current : Vector3 = _get_position(_node_ref)
	var distance : float = current.distance_to(target_pos)
	if distance <= maxf(eval(&"stop_distance") as float, 0.001):
		return tick_next(delta)
		
	var spd : float = eval(&"speed") as float
	var lookahead : float = clampf(distance / maxf(spd, 0.001), 0.0, eval(&"max_prediction") as float)
	var predicted : Vector3 = target_pos + target_vel * lookahead
	
	_step_towards(_node_ref, predicted, spd * delta)
	return Status.RUNNING

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func _step_towards(n: Node, destination: Vector3, max_step: float) -> float:
	var current : Vector3 = _get_position(n)
	var remaining : float = current.distance_to(destination)
	if remaining <= max_step or remaining <= 0.0001:
		_set_position(n, destination)
		return 0.0
	_set_position(n, current.move_toward(destination, max_step))
	return remaining - max_step

func set_instruction() -> String: return "Pursue {target} with {node} at speed {speed}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
