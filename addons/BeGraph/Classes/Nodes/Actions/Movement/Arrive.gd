@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Arrive"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves a node towards a target position or node and smoothly slows down within the arrival radius."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var max_speed : float = 200.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var slow_radius : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var target_radius : float = 10.0

var _node_ref : Node
var _target_ref : Node

func on_start() -> void:
	_node_ref = eval(&"node", true)
	if _node_ref == null:
		abort("couldn't resolve node to move")
		return
		
	var raw = eval(&"target")
	_target_ref = eval(&"target", true) if (raw is NodePath or raw is String) else null

func tick(delta: float) -> Status:
	if _node_ref == null or not is_instance_valid(_node_ref):
		return abort("couldn't resolve node to move")
		
	var dest = _resolve_target_pos()
	if dest == null:
		return abort("couldn't resolve target destination")
		
	var current : Vector3 = _get_position(_node_ref)
	var diff : Vector3 = (dest as Vector3) - current
	var dist : float = diff.length()
	
	if dist <= (eval(&"target_radius") as float):
		_set_position(_node_ref, dest)
		return Status.SUCCESS
		
	var max_s : float = eval(&"max_speed") as float
	var slow_r : float = maxf(eval(&"slow_radius") as float, 0.001)
	var desired_speed : float = max_s if dist > slow_r else max_s * (dist / slow_r)
	var step : float = minf(desired_speed * delta, dist)
	
	_set_position(_node_ref, current + diff.normalized() * step)
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_node_ref = null
	_target_ref = null

func _resolve_target_pos() -> Variant:
	if _target_ref != null and is_instance_valid(_target_ref):
		return _get_position(_target_ref)
	var raw = eval(&"target")
	if raw is Vector3: return raw
	if raw is Vector2: return Vector3(raw.x, raw.y, 0.0)
	var n : Node = eval(&"target", true)
	return _get_position(n) if n != null else null

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func set_instruction() -> String: return "Arrive {node} at {target} (slow radius: {slow_radius})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
