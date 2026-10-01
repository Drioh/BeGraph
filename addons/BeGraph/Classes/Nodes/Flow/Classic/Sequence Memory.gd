@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Sequence (Memory)"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Like Sequence, but remembers its progress.\n\nSuccessors are ticked in order. If one returns RUNNING, the following ticks resume from that same successor: the ones before it (which already succeeded in this pass) are not ticked again.\n\nThe pass ends, and the next tick starts again from the first successor, when a successor returns FAILURE (returns FAILURE) or when all of them have succeeded (returns SUCCESS)."

## Index of the successor currently being ticked in this pass.
var _position : int = 0

func set_instruction() -> String:
	return "Sequence (Memory)"

func tick(delta:float) -> Status:
	var count : int = _next_ref.size()
	if _position >= count:
		_position = 0

	while _position < count:
		var status : Status = tick_next(delta, _position)
		match status:
			Status.RUNNING:
				return Status.RUNNING # resume from this successor next tick
			Status.FAILURE:
				_position = 0
				return Status.FAILURE
			_:
				_position += 1 # SUCCESS: go on with the next one in the same tick

	_position = 0
	return Status.SUCCESS

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	pass
