@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Fire Animation Tree One Shot"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { FIRE, ABORT, FADE_OUT }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationTree") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var one_shot : StringName = &""
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Fire,Abort,FadeOut") var mode : Mode = Mode.FIRE

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node")) as AnimationTree
	if target == null:
		return abort("couldn't resolve AnimationTree")
		
	var req : int
	match eval(&"mode") as Mode:
		Mode.FIRE: req = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		Mode.ABORT: req = AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT
		_: req = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
		
	target.set("parameters/%s/request" % eval(&"one_shot"), req)
	return tick_next(delta)

func set_instruction() -> String: return "{mode} one shot {one_shot} on {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
