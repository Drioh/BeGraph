@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Push Error / Warning"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sends {message} to the debugger, either with push_error() or push_warning() depending on {mode}.\n\nAlways succeeds."

enum Mode { ERROR, WARNING }

func set_instruction() -> String:
	return "Push {mode}: {message}"

func tick(delta:float) -> Status:
	var message : String = str(get("message"))

	match get("mode"):
		Mode.ERROR:
			push_error(message)
		Mode.WARNING:
			push_warning(message)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Error,Warning")
	_add_behavior_property("message", "")
