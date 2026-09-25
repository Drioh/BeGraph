@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits {seconds}s, plus a random offset between {random_minimum} and {random_maximum} (rolled once per wait), returning RUNNING until the time elapses and SUCCESS afterwards.\n\nLeave {random_minimum}/{random_maximum} at 0 for a fixed wait.\n\nThe timer (and the roll) starts on the first tick."

var _elapsed : float = 0.0
var _target : float = 0.0

func set_instruction() -> String:
	return "Wait {seconds}s"

func tick(delta:float) -> Status:
	if dirty:
		_target = get("seconds") + randf_range(get("random_minimum"), get("random_maximum"))
		dirty = false

	_elapsed += delta
	if _elapsed >= _target:
		_elapsed = 0.0
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	return Status.RUNNING

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("seconds", float(1.0))
	_add_behavior_property("random_minimum", float(0.0))
	_add_behavior_property("random_maximum", float(0.0))
