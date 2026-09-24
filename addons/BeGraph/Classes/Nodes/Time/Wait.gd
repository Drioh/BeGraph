@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits {seconds} seconds, returning RUNNING until the time elapses and SUCCESS afterwards.\n\nThe timer starts on the first tick."

var _elapsed : float = 0.0

func set_instruction() -> String:
	return "Wait {seconds}s"

func tick(delta:float) -> Status:
	var seconds : float = get("seconds")

	_elapsed += delta
	if _elapsed >= seconds:
		_elapsed = 0.0
		tick_next(delta)
		return Status.SUCCESS

	return Status.RUNNING

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("seconds", float(1.0))
