@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait Until"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Returns RUNNING until {condition} becomes true, then ticks its successor and returns SUCCESS.\n\nLink {condition} to a blackboard variable to wait for something that changes while the graph runs.\n\nIf {timeout} is greater than 0, returns FAILURE when the condition is still false after that many seconds (0 = wait forever)."

var _elapsed : float = 0.0

func set_instruction() -> String:
	return "Wait until {condition} (timeout: {timeout}s)"

func tick(delta:float) -> Status:
	if bool(get("condition")):
		_elapsed = 0.0
		tick_next(delta)
		return Status.SUCCESS

	var timeout : float = get("timeout")
	if timeout > 0.0:
		_elapsed += delta
		if _elapsed >= timeout:
			_elapsed = 0.0
			return Status.FAILURE
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("condition", false)
	_add_behavior_property("timeout", float(0.0))
