@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "Random Selector"

func tick() -> Status:
	var shuffled : Array[BehaviorNode] = next.duplicate()
	shuffled.shuffle()

	for child in shuffled:
		var status : Status = child.tick()
		if status == Status.SUCCESS or status == Status.RUNNING:
			return status
	return Status.FAILURE

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	pass
