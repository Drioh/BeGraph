@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Behaves like Selector, but ticks its successors in a random order, stopping at the first SUCCESS or RUNNING.\n\nReturns FAILURE only if all successors fail.\n\nIf {memory} is false, the order is re-rolled on every tick: if a successor returns RUNNING, the next tick may pick a different one.\n\nIf {memory} is true, the order is rolled once per pass and a successor returning RUNNING is resumed on the following ticks (the ones that already failed are not retried). The pass ends on SUCCESS or when all successors have failed, and a new order is rolled on the next tick."

## Random order of successor indices for the current pass.
var _order : Array[int] = []
## Position inside [member _order] of the successor to resume from. Only meaningful while {memory} is true.
var _position : int = 0

func set_instruction() -> String:
	return "Random Selector (memory: {memory})"

func tick(delta:float) -> Status:
	var count : int = _next_ref.size()
	if count == 0:
		_reset()
		return Status.FAILURE

	var memory : bool = get("memory") == true

	if not memory or _order.size() != count:
		_start_pass(count)

	var i : int = _position
	while i < _order.size():
		var status : Status = tick_next(delta, _order[i]) # _order holds indices into _next_ref
		match status:
			Status.RUNNING:
				if memory:
					_position = i
				else:
					_reset()
				return Status.RUNNING
			Status.SUCCESS:
				_reset()
				return Status.SUCCESS
			_:
				i += 1 # FAILURE: try the next one in the same tick

	_reset()
	return Status.FAILURE

func _start_pass(count : int) -> void:
	_order.clear()
	for n in count:
		_order.append(n)
	_order.shuffle()
	_position = 0

func _reset() -> void:
	_order.clear()
	_position = 0

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	_add_behavior_property("memory", false)
