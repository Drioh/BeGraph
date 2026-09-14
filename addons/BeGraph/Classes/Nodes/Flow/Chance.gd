@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Chance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "Chance {probability}%"

func tick() -> Status:
	if randf() * 100.0 <= get("probability"):
		tick_condition(0)
	else:
		tick_condition(1)
	return Status.RUNNING

func set_node_category()->String:return "control_flow_node"
func set_input()->bool:return true
func set_output()->bool:return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("probability", float(50.0))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Success ({probability}%)",
		"Failure"
	])
