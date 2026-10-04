@tool
extends BehaviorNode

const DISPLAY_NAME : String = "AnimatedSprite Play"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Plays {animation} on {node} (an AnimatedSprite2D/3D) at {speed}, from the end if {backwards} is true. Leave {animation} empty to play the current one.\n\nIf {wait_until_finished} is true it returns RUNNING while the animation plays and SUCCESS once it finishes (a looping animation never finishes); otherwise it succeeds right after starting it.\n\nFails if {node} can't be resolved, has no SpriteFrames or doesn't have that animation."

var _started : bool = false

func set_instruction() -> String:
	return "Play {animation} on {node} at speed {speed}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if not (target is AnimatedSprite2D or target is AnimatedSprite3D):
		push_error("\"%s\" couldn't resolve an AnimatedSprite2D/3D" % resource_name)
		return Status.FAILURE

	if not _started:
		var animation : StringName = get("animation")
		if target.sprite_frames == null or (animation != &"" and not target.sprite_frames.has_animation(animation)):
			push_error("\"%s\": \"%s\" has no animation \"%s\"" % [resource_name, target, animation])
			return Status.FAILURE

		target.play(animation, get("speed"), get("backwards"))
		if not get("wait_until_finished"):
			tick_next(delta)
			return Status.SUCCESS
		_started = true
		return Status.RUNNING

	if target.is_playing():
		return Status.RUNNING

	_started = false
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("animation", &"")
	_add_behavior_property("speed", float(1.0))
	_add_behavior_property("backwards", false)
	_add_behavior_property("wait_until_finished", true)
