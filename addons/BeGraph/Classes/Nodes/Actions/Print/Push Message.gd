@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Push Message"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Pushes a warning or error message to the Godot debugger console."

enum Mode { WARNING, ERROR }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var message : String = ""
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Warning,Error") var mode : Mode = Mode.WARNING

func tick(_delta: float) -> Status:
	var msg : String = eval(&"message")
	match eval(&"mode") as Mode:
		Mode.WARNING: push_warning(msg)
		Mode.ERROR: push_error(msg)
	return Status.SUCCESS

func set_instruction() -> String: return "Push {mode}: {message}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
