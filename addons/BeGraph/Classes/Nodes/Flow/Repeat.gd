@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Repeat"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor repeatedly. Returns RUNNING while it's running, resets and returns FAILURE on a failure, and returns SUCCESS once the successor has succeeded {times} times in a row (0 = infinite)."

var _current_count : int = 0

func set_instruction() -> String:
	return "Repeat {times} times"

func tick() -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE

	var times : int = get("times")
	var status : Status = tick_next()

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
