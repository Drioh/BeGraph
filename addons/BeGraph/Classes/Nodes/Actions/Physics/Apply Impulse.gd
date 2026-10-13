@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Apply Impulse"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Applies an impulse vector to a RigidBody2D or RigidBody3D node."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"RigidBody2D,RigidBody3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var impulse : Vector3 = Vector3.ZERO

func tick(_delta: float) -> Status:
	var target : Node = eval(&"node", true)
	if target == null or not (target is RigidBody2D or target is RigidBody3D):
		return abort("couldn't resolve rigid body")
		
	var imp : Vector3 = eval(&"impulse") as Vector3
	if target is RigidBody2D:
		target.apply_impulse(Vector2(imp.x, imp.y))
	else:
		target.apply_impulse(imp)
		
	return Status.SUCCESS

func set_instruction() -> String: return "Apply impulse {impulse} to {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
