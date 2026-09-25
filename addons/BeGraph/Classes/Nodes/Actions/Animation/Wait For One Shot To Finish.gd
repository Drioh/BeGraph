@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For One Shot To Finish"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits for the AnimationNodeOneShot named {one_shot} inside {node} (an AnimationTree) to stop playing, returning RUNNING while its \"active\" parameter is true and SUCCESS once it turns false.\n\nFails if {node} can't be resolved or isn't an AnimationTree."

func set_instruction() -> String:
	return "Wait for one shot {one_shot} on {node}"

func tick(delta:float) -> Status:
	var target : AnimationTree = _resolve_node(get("node")) as AnimationTree
	if target == null:
		push_error("\"%s\" couldn't resolve AnimationTree" % resource_name)
		return Status.FAILURE

	if target.get("parameters/%s/active" % get("one_shot")):
		return Status.RUNNING

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AnimationTree", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("one_shot", &"")
