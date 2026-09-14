@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Cooldown"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

var _cooldown_until : int = -1

func set_instruction() -> String:
	return "Cooldown {seconds}s"

func tick() -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE

	if _cooldown_until != -1:
		if Time.get_ticks_msec() < _cooldown_until:
			return Status.FAILURE
		_cooldown_until = -1

	var status : Status = tick_next()
	if status != Status.RUNNING:
		_cooldown_until = Time.get_ticks_msec() + int(get("seconds") * 1000)
	return status

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("seconds", float(2.0))
