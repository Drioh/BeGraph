@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Print string message"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Prints the string in {value} to the console with print() and always succeeds.\n\nSame as 'Print message', but {value} is typed as String."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var value : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var print_rich : bool = false

var _value : String = ""
var _print_rich : bool = false

func tick(delta: float) -> Status:
	if eval(&"print_rich"):
		print_rich(eval(&"value"))
	else:
		print(eval(&"value"))
	
	tick_next(delta)
	return Status.SUCCESS

func set_instruction() -> String:
	return "Prints {value}"

func set_node_category() -> String: 
	return "action_node"

func set_input() -> bool: 
	return true

func set_output() -> bool: 
	return true

func set_allows_multiple_outputs() -> bool: 
	return false
