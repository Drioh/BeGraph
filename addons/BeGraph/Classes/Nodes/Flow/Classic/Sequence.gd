@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Sequence"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks each successor in order, stopping at the first that returns FAILURE or RUNNING and returning that status. Returns SUCCESS only if all successors succeed.\n\nClassic behavior-tree AND node."

func set_instruction() -> String:
	return "Sequence"

func tick(delta:float) -> Status:
	for i in _next_ref.size():
		var status : Status = tick_next(delta,i)
		if status == Status.FAILURE or status == Status.RUNNING:
			return status
	return Status.SUCCESS

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	pass
