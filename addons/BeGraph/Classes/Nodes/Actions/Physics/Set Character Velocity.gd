@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Character Velocity"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the velocity vector on a CharacterBody2D or CharacterBody3D node and calls move_and_slide()."

@export_custom(PROPERTY_HINT_NODE_TYPE,BG.PROPERTY+ "CharacterBody2D,CharacterBody3D" ) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var velocity : Vector3 = Vector3.ZERO

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not (target is CharacterBody2D or target is CharacterBody3D):
		return abort("couldn't resolve character body")
		
	var vel : Vector3 = eval(&"velocity") as Vector3
	if target is CharacterBody2D:
		target.velocity = Vector2(vel.x, vel.y)
	else:
		target.velocity = vel
		
	target.move_and_slide()
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s velocity to {velocity}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
