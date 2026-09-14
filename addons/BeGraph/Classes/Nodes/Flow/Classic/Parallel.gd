@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Parallel"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

enum Mode { N_OF_M, ALL }

func set_instruction() -> String:
	return "Parallel: {mode} mode"

func tick() -> Status:
	var mode : int = get("mode")
	var required_successes : int = _next_ref.size() if mode == Mode.ALL else get("required_successes")

	var successes := 0
	var failures := 0

	for i in _next_ref.size():
		var status : Status = tick_next(i)
		match status:
			Status.SUCCESS:
				successes += 1
			Status.FAILURE:
				failures += 1
				if mode == Mode.ALL:
					return Status.FAILURE

	if successes >= required_successes:
		return Status.SUCCESS
	if failures > _next_ref.size() - required_successes:
		return Status.FAILURE
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return true

func set_properties()-> void:
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Threshold,All")
	_add_behavior_property("required_successes", int(1))
