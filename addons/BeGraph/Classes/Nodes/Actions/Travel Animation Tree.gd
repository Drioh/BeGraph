@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Animation Tree Travel"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Tells the AnimationTree {anim_tree} to travel to the state machine node {state}.\n\nReturns RUNNING until the target state is reached, then SUCCESS; fails if {anim_tree} cannot be resolved."

var _anim_tree : AnimationTree
var _playback : AnimationNodeStateMachinePlayback

func set_instruction() -> String:
	return "Travel {anim_tree} to state {state}"

func tick() -> Status:
	if dirty:
		_anim_tree = _resolve_node(get("anim_tree")) as AnimationTree
		if _anim_tree == null:
			push_error("\"%s\" couldn't resolve AnimationTree" % resource_name)
			return Status.FAILURE
		_playback = _anim_tree.get("parameters/playback")
		_playback.travel(get("state"))
		dirty = false

	if _playback.get_current_node() != get("state"):
		return Status.RUNNING

	dirty = true
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("anim_tree", NodePath(""))
	_add_behavior_property("state", &"")
