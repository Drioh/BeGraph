@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Animation Tree Travel"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Commands an AnimationTree state machine to travel to a designated state and waits until that state is reached."

@export_custom(BG.HINT_NONE, BG.PROPERTY+"AnimationTree") var anim_tree : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var state : StringName = &""

var _playback : AnimationNodeStateMachinePlayback

func on_start() -> void:
	var tree_node := eval(&"anim_tree", true) as AnimationTree
	if tree_node == null:
		abort("couldn't resolve AnimationTree")
		return
		
	_playback = tree_node.get("parameters/playback")
	if _playback == null:
		abort("couldn't find state machine playback in AnimationTree")
		return
		
	_playback.travel(eval(&"state"))

func tick(_delta: float) -> Status:
	if _playback == null:
		return Status.FAILURE
	if _playback.get_current_node() != eval(&"state"):
		return Status.RUNNING
	return Status.SUCCESS

func on_end(_status: Status) -> void:
	_playback = null

func set_instruction() -> String: return "Travel {anim_tree} to state {state}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
