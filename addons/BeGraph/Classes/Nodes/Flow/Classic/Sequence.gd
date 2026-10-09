@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Sequence"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks each successor in order, stopping at the first that returns FAILURE or RUNNING."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var memory : bool = false

var _position : int = 0

func on_start() -> void:
	if not eval(&"memory"):
		_position = 0

func tick(delta: float) -> Status:
	var use_memory : bool = eval(&"memory") as bool
	var count : int = _next_ref.size()
	
	if not use_memory or _position >= count:
		_position = 0
		
	var i : int = _position
	while i < count:
		var status : Status = tick_next(delta, i)
		match status:
			Status.RUNNING:
				_position = i if use_memory else 0
				return Status.RUNNING
			Status.FAILURE, Status.ERROR:
				_position = 0
				return status
		i += 1
		
	_position = 0
	return Status.SUCCESS

func set_instruction() -> String: return "Sequence (memory: {memory})"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return true
