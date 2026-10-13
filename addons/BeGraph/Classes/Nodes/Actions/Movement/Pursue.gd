@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Pursue"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Predicts the target's future position based on its velocity and moves towards it."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var target : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 120.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var max_prediction : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var target_radius : float = 15.0

var _node_ref : Node
var _target_ref : Node

func on_start() -> void:
	_node_ref = eval(&"node", true)
	_target_ref = eval(&"target", true)
	if _node_ref == null:
		abort("couldn't resolve node")
	if _target_ref == null:
		abort("couldn't resolve target node")

func tick(delta: float) -> Status:
	if _node_ref == null or not is_instance_valid(_node_ref):
		return abort("couldn't resolve node")
	if _target_ref == null or not is_instance_valid(_target_ref):
		return abort("couldn't resolve target node")
		
	var self_pos : Vector3 = _get_position(_node_ref)
	var tgt_pos : Vector3 = _get_position(_target_ref)
	var dist : float = self_pos.distance_to(tgt_pos)
	
	if dist <= (eval(&"target_radius") as float):
		return Status.SUCCESS
		
	var my_speed : float = maxf(eval(&"speed") as float, 0.001)
	var time_to_reach : float = minf(dist / my_speed, eval(&"max_prediction") as float)
	var predicted : Vector3 = tgt_pos + _get_velocity(_target_ref) * time_to_reach
	
	_step_towards(_node_ref, predicted, my_speed * delta)
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_node_ref = null
	_target_ref = null

func _get_velocity(n: Node) -> Vector3:
	if "velocity" in n:
		var v = n.get("velocity")
		return Vector3(v.x, v.y, 0.0) if v is Vector2 else v
	if "linear_velocity" in n:
		var lv = n.get("linear_velocity")
		return Vector3(lv.x, lv.y, 0.0) if lv is Vector2 else lv
	return Vector3.ZERO

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func _step_towards(n: Node, dest: Vector3, max_step: float) -> float:
	var curr : Vector3 = _get_position(n)
	var rem : float = curr.distance_to(dest)
	if rem <= max_step or rem <= 0.0001:
		_set_position(n, dest)
		return 0.0
	_set_position(n, curr.move_toward(dest, max_step))
	return rem - max_step

func set_instruction() -> String: return "Pursue {target} with {node} (speed: {speed})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
