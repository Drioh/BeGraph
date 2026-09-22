@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Follow Path"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Advances {path_follow} (PathFollow2D/3D) along its Path at {speed} units/second.\n\nReturns RUNNING while travelling, SUCCESS at the end of the path (or keeps looping if {loop} is enabled). Fails if {path_follow} can't be resolved."

var _path_follow : Node
var _last_tick_time : int = -1

func set_instruction() -> String:
	return "Move {path_follow} along its path at speed {speed}"

func tick() -> Status:
	if dirty:
		_path_follow = _resolve_node(get("path_follow"))
		if _path_follow == null:
			push_error("\"%s\" couldn't resolve PathFollow node" % resource_name)
			return Status.FAILURE
		_last_tick_time = Time.get_ticks_msec()
		dirty = false

	var now : int = Time.get_ticks_msec()
	var delta : float = (now - _last_tick_time) / 1000.0
	_last_tick_time = now

	_path_follow.progress += get("speed") * delta

	if _path_follow.progress_ratio >= 1.0:
		if get("loop"):
			_path_follow.progress_ratio = fmod(_path_follow.progress_ratio, 1.0)
			return Status.RUNNING
		_path_follow.progress_ratio = 1.0
		dirty = true
		return Status.SUCCESS

	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("path_follow", NodePath(""))
	_add_behavior_property("speed", float(100.0))
	_add_behavior_property("loop", false)
