@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Animation Playing"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (an AnimationPlayer, AnimatedSprite2D or AnimatedSprite3D) is currently playing, branching to 'Playing' or 'Not playing'.\n\nIf {animation} isn't empty, it must also be the animation currently playing.\n\nDoesn't block: it only reads the current state. Fails if {node} can't be resolved or isn't supported."

func set_instruction() -> String:
	return "Check if {node} is playing {animation}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	var playing : bool
	var current : String
	if target is AnimationPlayer:
		playing = target.is_playing()
		current = String(target.current_animation)
	elif target is AnimatedSprite2D or target is AnimatedSprite3D:
		playing = target.is_playing()
		current = String(target.animation)
	else:
		push_error("\"%s\" couldn't resolve an animation player/animated sprite" % resource_name)
		return Status.FAILURE

	var wanted : String = String(get("animation"))
	if wanted != "":
		playing = playing and current == wanted

	if playing:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("animation", &"")

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Playing",
		"Not playing"
	])
