@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Time Limit"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor, but forces FAILURE if it hasn't finished within {seconds}s."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var seconds : float = 5.0

var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0

func tick(delta: float) -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE
		
	_elapsed += delta
	if _elapsed >= (eval(&"seconds") as float):
		_elapsed = 0.0
		return Status.FAILURE
		
	var status : Status = tick_next(delta)
	if status != Status.RUNNING:
		_elapsed = 0.0
		
	return status

func set_instruction() -> String: return "Time Limit {seconds}s"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
