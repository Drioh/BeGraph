@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Print message"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Prints {value} to the console with print() and always succeeds.\n\n {value} accepts any type; useful for debugging graph execution."

func tick(delta:float)->Status:
	var _value = get("value")
	tick_next(delta)
	return Status.SUCCESS 

func set_instruction() -> String:
	return "Prints {value}"

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("value",null ,PROPERTY_HINT_NONE,"","","",PROPERTY_USAGE_NIL_IS_VARIANT)
	
