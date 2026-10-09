@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Flee"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 150.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var safe_distance : float = 300.0

var _node_ref : Node

func on_start() -> void:
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node to flee with")

func tick(delta: float) -> Status:
	var threat_pos = _resolve_position(eval(&"target"))
	if threat_pos == null:
		return abort("couldn't resolve target threat position")
		
	var current : Vector3 = _get_position(_node_ref)
	var away : Vector3 = current - threat_pos
	var distance : float = away.length()
	
	if distance >= (eval(&"safe_distance") as float):
		return tick_next(delta)
		
	var dir : Vector3 = away / distance if distance > 0.0001 else _random_direction(_node_ref is Node3D)
	_set_position(_node_ref, current + dir * (eval(&"speed") as float) * delta)
	return Status.RUNNING

func _resolve_position(value: Variant) -> Variant:
	if value is Vector3: return value
	if value is Vector2: return Vector3(value.x, value.y, 0.0)
	var n : Node = _resolve_node(value)
	return _get_position(n) if n != null else null

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func _random_direction(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle)) if in_3d else Vector3(cos(angle), sin(angle), 0.0)

func set_instruction() -> String: return "Flee from {target} with {node} until {safe_distance} away"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
