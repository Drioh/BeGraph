@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Keep Distance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves a node to maintain a desired distance (within a tolerance margin) from a target node."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var target_distance : float = 200.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var tolerance : float = 20.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 0.0

var _node_ref : Node
var _target_ref : Node
var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_node_ref = eval(&"node", true)
	if _node_ref == null:
		abort("couldn't resolve node")
		return
		
	var raw = eval(&"target")
	_target_ref = eval(&"target", true) if (raw is NodePath or raw is String) else null

func tick(delta: float) -> Status:
	if _node_ref == null or not is_instance_valid(_node_ref):
		return abort("couldn't resolve node")
		
	var dest = _resolve_target_pos()
	if dest == null:
		return abort("couldn't resolve target position")
		
	var current : Vector3 = _get_position(_node_ref)
	var diff : Vector3 = current - (dest as Vector3)
	var dist : float = diff.length()
	var desired : float = eval(&"target_distance") as float
	var tol : float = eval(&"tolerance") as float
	
	if absf(dist - desired) <= tol:
		return Status.SUCCESS
		
	var dur : float = eval(&"duration") as float
	if dur > 0.0:
		_elapsed += delta
		if _elapsed >= dur:
			return Status.SUCCESS
			
	var dir : Vector3 = diff.normalized() if dist > 0.001 else _random_dir(_node_ref is Node3D)
	var sign_val : float = 1.0 if dist < desired else -1.0
	_set_position(_node_ref, current + dir * sign_val * (eval(&"speed") as float) * delta)
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_node_ref = null
	_target_ref = null
	_elapsed = 0.0

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

func _random_dir(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle)) if in_3d else Vector3(cos(angle), sin(angle), 0.0)

func set_instruction() -> String: return "Keep {target_distance} distance between {node} and {target}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
