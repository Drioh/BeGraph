@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Timer Wait"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Starts {timer} (a Timer node) as one-shot with {wait_time}s and returns RUNNING until it times out, then SUCCESS.\n\nFails if {timer} can't be resolved."

var _timer : Timer
var _fired : bool = false

func set_instruction() -> String:
	return "Wait for {timer} ({wait_time}s)"

func tick() -> Status:
	if dirty:
		_timer = _resolve_node(get("timer")) as Timer
		if _timer == null:
			push_error("\"%s\" couldn't resolve Timer node" % resource_name)
			return Status.FAILURE

		if not _timer.timeout.is_connected(_on_timeout):
			_timer.timeout.connect(_on_timeout, CONNECT_ONE_SHOT)

		_fired = false
		_timer.wait_time = max(get("wait_time"), 0.001)
		_timer.one_shot = true
		_timer.start()
		dirty = false

	if _fired:
		dirty = true
		tick_next()
		return Status.SUCCESS

	return Status.RUNNING

func _on_timeout() -> void:
	_fired = true

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("timer", NodePath(""))
	_add_behavior_property("wait_time", float(1.0))
