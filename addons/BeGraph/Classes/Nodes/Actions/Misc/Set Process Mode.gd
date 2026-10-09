@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Process Mode"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Inherit,Pausable,When Paused,Always,Disabled") var mode : int = 0

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")
		
	target.process_mode = (eval(&"mode") as int) as Node.ProcessMode
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s process mode: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
