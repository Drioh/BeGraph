@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Light Color"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the color of a Light2D or Light3D node."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Light2D,Light3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var color : Color = Color.WHITE

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not (target is Light2D or target is Light3D):
		return abort("couldn't resolve light node")
		
	var prop_name : String = "color" if target is Light2D else "light_color"
	target.set(prop_name, eval(&"color"))
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s color to {color}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
