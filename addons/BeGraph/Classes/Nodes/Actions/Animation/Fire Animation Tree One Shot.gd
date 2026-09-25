@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Fire Animation Tree One Shot"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sends a request to the AnimationNodeOneShot named {one_shot} inside {node} (an AnimationTree): Fire, Abort, or FadeOut, depending on {mode}.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't an AnimationTree."

enum Mode { FIRE, ABORT, FADE_OUT }

func set_instruction() -> String:
	return "{mode} one shot {one_shot} on {node}"

func tick(delta:float) -> Status:
	var target : AnimationTree = _resolve_node(get("node")) as AnimationTree
	if target == null:
		push_error("\"%s\" couldn't resolve AnimationTree" % resource_name)
		return Status.FAILURE

	var request : int
	match get("mode"):
		Mode.FIRE: request = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		Mode.ABORT: request = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		_: request = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT

	target.set("parameters/%s/request" % get("one_shot"), request)
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AnimationTree", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("one_shot", &"")
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Fire,Abort,FadeOut")
