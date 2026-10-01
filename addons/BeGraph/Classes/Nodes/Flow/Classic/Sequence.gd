@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Sequence"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks each successor in order, stopping at the first that returns FAILURE or RUNNING and returning that status. Returns SUCCESS only if all successors succeed.\n\nClassic behavior-tree AND node.\n\nIf {memory} is false, every tick starts again from the first successor (reactive).\n\nIf {memory} is true, a successor returning RUNNING is resumed on the following ticks: the ones before it, which already succeeded in this pass, are not ticked again. The pass ends on FAILURE or when all successors have succeeded."

## Index of the successor to resume from. Only meaningful while {memory} is true.
var _position : int = 0

func set_instruction() -> String:
	return "Sequence (memory: {memory})"

func tick(delta:float) -> Status:
	var memory : bool = get("memory") == true
	var count : int = _next_ref.size()

	# Without memory the pass always starts from scratch. This also discards any
	# stale position if {memory} gets turned off (and back on) at runtime.
	if not memory or _position >= count:
		_position = 0

	var i : int = _position
	while i < count:
		var status : Status = tick_next(delta, i)
		match status:
			Status.RUNNING:
				_position = i if memory else 0
				return Status.RUNNING
			Status.FAILURE:
				_position = 0
				return Status.FAILURE
			_:
				i += 1 # SUCCESS: go on with the next one in the same tick

	_position = 0
	return Status.SUCCESS

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	_add_behavior_property("memory", false)
