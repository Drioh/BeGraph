@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Repeat"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

var _current_count : int = 0

func set_instruction() -> String:
	return "Repeat {times} times"

func tick() -> Status:
	if next.size() == 0:
		return Status.FAILURE

	var times : int = get("times")
	var status : Status = next[0].tick()

	if status == Status.RUNNING:
		return Status.RUNNING

	if status == Status.FAILURE:
		_current_count = 0
		return Status.FAILURE

	_current_count += 1
	if times > 0 and _current_count >= times:
		_current_count = 0
		return Status.SUCCESS

	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("times", int(3))
