@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Light Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Enables, disables, or toggles visibility on a Light2D or Light3D node."

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Light2D,Light3D" ) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON

func tick(_delta: float) -> Status:
	var target :Node= eval(&"node", true)
	if target == null or not (target is Light2D or target is Light3D):
		return abort("couldn't resolve light node")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.visible = true
		Mode.OFF: target.visible = false
		Mode.TOGGLE: target.visible = not target.visible
		
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s light: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
