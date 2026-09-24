@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Animator"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Plays {animation} on {animator} (AnimationPlayer) at {speed}. \n\nReturns RUNNING while the animation plays and SUCCESS once it finishes; fails if {animator} cannot be resolved."

var _started : bool = false

func set_instruction() -> String:
	return "Play {animation} on {animator} at speed {speed}"

func tick() -> Status:
	var animator : AnimationPlayer = _resolve_node(get("animator")) as AnimationPlayer
	if animator == null:
		push_error("\"%s\" couldn't resolve AnimationPlayer" % resource_name)
		return Status.FAILURE

	if not _started:
		animator.play(get("animation"), -1, get("speed"))
		_started = true
		return Status.RUNNING

	if animator.is_playing():
		return Status.RUNNING

	_started = false
	tick_next()
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("animator", NodePath(""))
	_add_behavior_property("animation", &"")
	_add_behavior_property("speed", float(1.0))
