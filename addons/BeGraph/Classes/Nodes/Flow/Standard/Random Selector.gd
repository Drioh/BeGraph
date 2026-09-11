@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "Random Selector"

func tick() -> Status:
	var shuffled : Array[BehaviorNode] = _next_ref.duplicate()
	shuffled.shuffle()

	for i in shuffled.size():
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
