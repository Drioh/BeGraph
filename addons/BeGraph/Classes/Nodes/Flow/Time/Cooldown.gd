@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Cooldown"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor normally, but returns FAILURE immediately for {seconds}s after it last stopped running."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var seconds : float = 2.0

var _cooldown_remaining : float = -1.0

func tick(delta: float) -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE
		
	if _cooldown_remaining != -1.0:
		_cooldown_remaining -= delta
		if _cooldown_remaining > 0.0:
			return Status.FAILURE
		_cooldown_remaining = -1.0
		
	var status : Status = tick_next(delta)
	if status != Status.RUNNING:
		_cooldown_remaining = eval(&"seconds") as float
		
	return status

func set_instruction() -> String: return "Cooldown {seconds}s"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
