@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Inverter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor and inverts the outcome: SUCCESS becomes FAILURE and vice versa."

func tick(delta: float) -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE
		
	var status : Status = tick_next(delta)
	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
	return status

func set_instruction() -> String: return "Inverter"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
