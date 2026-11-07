@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Print"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Prints a string or blackboard variable to the console."

@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(_delta: float) -> Status:
	var target_value := eval(&"value")
	print(target_value)
	return Status.SUCCESS

func set_instruction() -> String: return "Print {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
