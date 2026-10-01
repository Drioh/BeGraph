@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Behaves like Selector, but ticks its successors in a random order, stopping at the first SUCCESS or RUNNING.\n\nThe order is re-rolled on every tick (no memory): if a successor returns RUNNING, the next tick may pick a different one. Use 'Random Selector (Memory)' to keep the running successor.\n\nReturns FAILURE only if all successors fail."

func set_instruction() -> String:
	return "Random Selector"

func tick(delta:float) -> Status:
	var count : int = _next_ref.size()
	if count == 0:
		return Status.FAILURE

	var order : Array[int] = []
	order.resize(count)
	for i in count:
		order[i] = i
	order.shuffle()

	for index in order:
		var status : Status = tick_next(delta, index)
		if status == Status.SUCCESS or status == Status.RUNNING:
			return status
	return Status.FAILURE

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	pass
