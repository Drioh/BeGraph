@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks each successor in order, stopping at the first that returns SUCCESS or RUNNING and returning that status.\n\nReturns FAILURE only if all successors fail. Classic behavior-tree OR node."

func set_instruction() -> String:
	return "Selector"

func tick() -> Status:
	for i in _next_ref.size():
		var status : Status = tick_next(i)
		if status == Status.SUCCESS or status == Status.RUNNING:
			return status
	return Status.FAILURE

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	pass
