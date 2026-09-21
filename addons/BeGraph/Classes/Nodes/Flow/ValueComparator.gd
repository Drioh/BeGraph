@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Value Comparator"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Compares {value_1} to {value_2} and branches to the matching condition ('>', '=' or '<').\n\nHas no plain output; the next node is always chosen through its conditions."

func set_instruction() -> String:
	return "Compare {value_1} and {value_2}"

func tick() -> Status:
	var value_1 = get("value_1")
	var value_2 = get("value_2")
	
	if value_1>value_2:
		tick_condition(0)
		return Status.RUNNING
	if value_1==value_2:
		tick_condition(1)
		return Status.RUNNING
	if value_1<value_2:
		tick_condition(2)
		return Status.RUNNING
	return Status.FAILURE

func set_node_category()->String:return "control_flow_node"

func set_input()->bool:return true

func set_output()->bool:return false

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("value_1",int(0))
	_add_behavior_property("value_2",int(0))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"{value_1} > {value_2}",
		"{value_1} = {value_2}",
		"{value_1} < {value_2}"
	])
