@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Print String"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Prints a string to the console."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var text : String = ""

func tick(_delta: float) -> Status:
	var target_text := eval(&"text")
	print(target_text)
	return Status.SUCCESS

func set_instruction() -> String: return "Print {text}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
