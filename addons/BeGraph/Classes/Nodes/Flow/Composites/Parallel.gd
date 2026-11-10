@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Parallel"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks every successor on the same tick."

enum Mode { THRESHOLD, ALL }

@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Threshold,All", PROPERTY_USAGE_DEFAULT) var mode : Mode = Mode.THRESHOLD
@export_custom(BG.HINT_NONE, BG.PROPERTY) var required_successes : int = 1

var _finished_children : Dictionary = {}

func on_start() -> void:
	_finished_children.clear()

func on_end(_status: Status) -> void:
	_finished_children.clear()

func _on_abort_running(_visited: Dictionary) -> void:
	_finished_children.clear()

func _abort_remaining_children() -> void:
	_finished_children.clear()
	var graph := get_graph()
	if graph == null:
		return
	for next_name in _next_ref:
		var child : BehaviorNode = graph.nodes.get(next_name, null)
		if child != null:
			child.abort_running()

func tick(delta: float) -> Status:
	var current_mode : Mode = eval(&"mode") as Mode
	var required : int = _next_ref.size() if current_mode == Mode.ALL else eval(&"required_successes") as int
	var successes : int = 0
	var failures : int = 0
	
	for i in _next_ref.size():
		var status : Status = _finished_children[i] if _finished_children.has(i) else tick_next(delta, i)
		match status:
			Status.SUCCESS:
				_finished_children[i] = Status.SUCCESS
				successes += 1
			Status.FAILURE:
				_finished_children[i] = Status.FAILURE
				failures += 1
			Status.ERROR:
				_abort_remaining_children()
				return Status.ERROR
				
		if current_mode == Mode.ALL and status == Status.FAILURE:
			_abort_remaining_children()
			return Status.FAILURE
			
	if successes >= required:
		_abort_remaining_children()
		return Status.SUCCESS
	if failures > _next_ref.size() - required:
		_abort_remaining_children()
		return Status.FAILURE
		
	return Status.RUNNING

func set_instruction() -> String: return "Parallel: {mode} mode"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return true
