@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Camera Current"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets a Camera2D or Camera3D node as the current active camera."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Camera2D,Camera3D") var node : NodePath = NodePath("")

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not (target is Camera2D or target is Camera3D):
		return abort("couldn't resolve camera node")
		
	if target is Camera2D:
		target.make_current()
	else:
		target.current = true
		
	return Status.SUCCESS

func set_instruction() -> String: return "Make {node} current camera"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
