@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Repeat"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor repeatedly."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var times : int = 3

var _current_count : int = 0

func on_start() -> void:
	_current_count = 0

func tick(delta: float) -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE
		
	var total_times : int = eval(&"times") as int
	var status : Status = tick_next(delta)
	
	if status == Status.RUNNING:
		return Status.RUNNING
	if status == Status.FAILURE or status == Status.ERROR:
		_current_count = 0
		return status
		
	_current_count += 1
	if total_times > 0 and _current_count >= total_times:
		_current_count = 0
		return Status.SUCCESS
		
	return Status.RUNNING

func set_instruction() -> String: return "Repeat {times} times"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
