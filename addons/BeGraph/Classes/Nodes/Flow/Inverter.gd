@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Inverter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "Inverter"

func tick() -> Status:
	if next.size() == 0:
		return Status.FAILURE
	var status : Status = next[0].tick()
	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		_:
			return status

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	pass
