@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Selector (Memory)"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Like Random Selector, but remembers its progress.\n\nA random order is rolled once per pass. If a successor returns RUNNING, the following ticks resume from that same successor (the order is not re-rolled and successors that already failed in this pass are not retried).\n\nThe pass ends, and a new order is rolled on the next tick, when a successor returns SUCCESS (returns SUCCESS) or when all of them have failed (returns FAILURE)."

## Random order of successor indices for the current pass (empty = no pass in progress).
var _order : Array[int] = []
## Position inside [member _order] of the successor currently being ticked.
var _position : int = 0

func set_instruction() -> String:
	return "Random Selector (Memory)"

func tick(delta:float) -> Status:
	var count : int = _next_ref.size()
	if count == 0:
		_reset()
		return Status.FAILURE

	# Starts a new pass (or recovers if the number of successors changed).
	if _order.size() != count:
		_start_pass(count)

	while _position < _order.size():
		var status : Status = tick_next(delta, _order[_position])
		match status:
			Status.RUNNING:
				return Status.RUNNING # stay on this successor next tick
			Status.SUCCESS:
				_reset()
				return Status.SUCCESS
			_:
				_position += 1 # FAILURE: try the next one in the same tick

	_reset()
	return Status.FAILURE

func _start_pass(count : int) -> void:
	_order.clear()
	for i in count:
		_order.append(i)
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
	pass
