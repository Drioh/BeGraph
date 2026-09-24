@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits {seconds} seconds, returning RUNNING until the time elapses and SUCCESS afterwards.\n\nThe timer starts on the first tick."

var _start_time : int = -1

func set_instruction() -> String:
	return "Wait {seconds}s"

func tick() -> Status:
	var seconds : float = get("seconds")

	if _start_time == -1:
		_start_time = Time.get_ticks_msec()

	var elapsed : float = (Time.get_ticks_msec() - _start_time) / 1000.0
	if elapsed >= seconds:
		_start_time = -1
		tick_next()
		return Status.SUCCESS

	return Status.RUNNING

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("seconds", float(1.0))
