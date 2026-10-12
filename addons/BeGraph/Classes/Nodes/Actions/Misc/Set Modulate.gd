@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Modulate"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { MODULATE, SELF_MODULATE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CanvasItem") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Modulate,SelfModulate") var mode : Mode = Mode.MODULATE
@export_custom(BG.HINT_NONE, BG.PROPERTY) var color : Color = Color.WHITE

func tick(delta: float) -> Status:
	var target := eval(&"node",true) as CanvasItem
	if target == null:
		return abort("couldn't resolve CanvasItem")
		
	var prop : String = "modulate" if (eval(&"mode") as Mode) == Mode.MODULATE else "self_modulate"
	target.set(prop, eval(&"color"))
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s {mode} to {color}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
