@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Animation Tree Travel"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"AnimationTree") var anim_tree : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var state : StringName = &""

var _playback : AnimationNodeStateMachinePlayback

func on_start() -> void:
	var tree_node := _resolve_node(eval(&"anim_tree")) as AnimationTree
	if tree_node == null:
		abort("couldn't resolve AnimationTree")
		return
		
	_playback = tree_node.get("parameters/playback")
	if _playback == null:
		abort("couldn't find state machine playback in AnimationTree")
		return
		
	_playback.travel(eval(&"state"))

func tick(delta: float) -> Status:
	if _playback != null and _playback.get_current_node() != eval(&"state"):
		return Status.RUNNING
	return tick_next(delta)

func set_instruction() -> String: return "Travel {anim_tree} to state {state}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
