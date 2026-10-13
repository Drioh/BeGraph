@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Position"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Instantly teleports a Node2D or Node3D to a target position in global or local space."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var position : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var global_space : bool = true

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not (target is Node2D or target is Node3D):
		return abort("couldn't resolve Node2D/Node3D target")
		
	var raw_pos = eval(&"position")
	var point_pos = _resolve_position(raw_pos)
	if point_pos == null:
		return abort("couldn't resolve target position")
		
	var dest : Vector3 = point_pos
	var is_vec : bool = raw_pos is Vector2 or raw_pos is Vector3
	
	if eval(&"global_space") or not is_vec:
		_set_position(target, dest)
	elif target is Node2D:
		target.position = Vector2(dest.x, dest.y)
	else:
		target.position = dest
		
	return Status.SUCCESS

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

func set_instruction() -> String: return "Teleport {node} to {position}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
