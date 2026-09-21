@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Follow Path"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

var _path_follow : Node
var _last_tick_time : int = -1
var first_time : bool = true

func set_instruction() -> String:
	return "Move {path_follow} along its path at speed {speed}"

func tick() -> Status:
	if first_time:
		_path_follow = _resolve_node(get("path_follow"))
		if _path_follow == null:
			push_error("\"%s\" couldn't resolve PathFollow node" % resource_name)
			return Status.FAILURE
		_last_tick_time = Time.get_ticks_msec()
		first_time = false

	var now : int = Time.get_ticks_msec()
	var delta : float = (now - _last_tick_time) / 1000.0
	_last_tick_time = now

	_path_follow.progress += get("speed") * delta

	if _path_follow.progress_ratio >= 1.0:
		if get("loop"):
			_path_follow.progress_ratio = fmod(_path_follow.progress_ratio, 1.0)
			return Status.RUNNING
		_path_follow.progress_ratio = 1.0
		first_time = true
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
