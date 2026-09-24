@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Inverter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor and inverts the outcome: SUCCESS becomes FAILURE and vice versa. \n\nRUNNING passes through unchanged. Fails if it has no successor."

func set_instruction() -> String:
	return "Inverter"

func tick() -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE
	var status : Status = tick_next()
	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			tick_next()
			return Status.SUCCESS
		_:
			return status

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	pass
