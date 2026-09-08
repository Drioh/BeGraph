@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Value Comparator"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "Compare {value_1} and {value_2}"

func tick() -> Status:
	var value_1 = get("value_1")
	var value_2 = get("value_2")
	
	if value_1>value_2:
		conditions[0]["next"].tick()
		return Status.RUNNING
	if value_1==value_2:
		conditions[1]["next"].tick()
		return Status.RUNNING
	if value_1<value_2:
		conditions[2]["next"].tick()
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
