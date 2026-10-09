@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var memory : bool = false

var _order : Array[int] = []
var _position : int = 0

func on_start() -> void:
	if not eval(&"memory"):
		_reset()

func tick(delta: float) -> Status:
	var count : int = _next_ref.size()
	if count == 0:
		_reset()
		return Status.FAILURE
		
	var use_memory : bool = eval(&"memory") as bool
	if not use_memory or _order.size() != count:
		_start_pass(count)
		
	var i : int = _position
	while i < _order.size():
		var status : Status = tick_next(delta, _order[i])
		match status:
			Status.RUNNING:
				if use_memory: _position = i
				else: _reset()
				return Status.RUNNING
			Status.SUCCESS:
				_reset()
				return Status.SUCCESS
			Status.ERROR:
				_reset()
				return Status.ERROR
		i += 1
		
	_reset()
	return Status.FAILURE

func _start_pass(count : int) -> void:
	_order.clear()
	for n in count: _order.append(n)
	_order.shuffle()
	_position = 0

func _reset() -> void:
	_order.clear()
	_position = 0

func set_instruction() -> String: return "Random Selector (memory: {memory})"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return true
