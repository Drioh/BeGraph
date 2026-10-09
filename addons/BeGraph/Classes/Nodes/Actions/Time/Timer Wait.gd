@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Timer Wait"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"Timer") var timer : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var wait_time : float = 1.0

var _timer_ref : Timer
var _fired : bool = false

func on_start() -> void:
	_fired = false
	_timer_ref = _resolve_node(eval(&"timer")) as Timer
	if _timer_ref == null:
		abort("couldn't resolve Timer node")
		return
		
	if not _timer_ref.timeout.is_connected(_on_timeout):
		_timer_ref.timeout.connect(_on_timeout, CONNECT_ONE_SHOT)
		
	_timer_ref.wait_time = maxf(eval(&"wait_time") as float, 0.001)
	_timer_ref.one_shot = true
	_timer_ref.start()

func tick(delta: float) -> Status:
	if _fired:
		return tick_next(delta)
	return Status.RUNNING

func _on_timeout() -> void:
	_fired = true

func on_end(_status: Status) -> void:
	if _timer_ref != null and is_instance_valid(_timer_ref):
		if _timer_ref.timeout.is_connected(_on_timeout):
			_timer_ref.timeout.disconnect(_on_timeout)
		_timer_ref.stop()

func set_instruction() -> String: return "Wait for {timer} ({wait_time}s)"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
