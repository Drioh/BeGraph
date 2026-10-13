@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Modulate"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the modulate or self_modulate color of a CanvasItem node."

enum Target { MODULATE, SELF_MODULATE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CanvasItem") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Modulate,SelfModulate") var target_property : Target = Target.MODULATE
@export_custom(BG.HINT_NONE, BG.PROPERTY) var color : Color = Color.WHITE

func tick(_delta: float) -> Status:
	var target :CanvasItem= eval(&"node", true) as CanvasItem
	if target == null:
		return abort("couldn't resolve CanvasItem")
		
	var c : Color = eval(&"color") as Color
	if (eval(&"target_property") as Target) == Target.SELF_MODULATE:
		target.self_modulate = c
	else:
		target.modulate = c
		
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s {target_property} to {color}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
