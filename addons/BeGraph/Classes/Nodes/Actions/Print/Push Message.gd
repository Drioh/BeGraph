@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Push Error / Warning"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ERROR, WARNING }

@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Error,Warning") var mode : Mode = Mode.ERROR
@export_custom(BG.HINT_NONE, BG.PROPERTY) var message : String = ""

func tick(delta: float) -> Status:
	var msg : String = str(eval(&"message"))
	if (eval(&"mode") as Mode) == Mode.ERROR:
		push_error(msg)
	else:
		push_warning(msg)
		
	return tick_next(delta)

func set_instruction() -> String: return "Push {mode}: {message}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
