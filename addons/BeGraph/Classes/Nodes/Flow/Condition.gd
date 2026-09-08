@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Condition"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "If {condition}"

func tick() -> Status:
	var condition : bool = get("condition")
	if condition and next.size() > 0:
		return next[0].tick()
	return Status.FAILURE

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("condition", false)
