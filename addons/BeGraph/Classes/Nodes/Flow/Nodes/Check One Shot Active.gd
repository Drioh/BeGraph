@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check One Shot Active"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether the AnimationNodeOneShot named {one_shot} inside {node} (an AnimationTree) is currently playing, branching to 'Active' or 'Inactive'.\n\nUnlike \"Wait For One Shot To Finish\", this doesn't block: it only reads the current state, so the rest of the graph keeps ticking.\n\nFails if {node} can't be resolved or isn't an AnimationTree."

func set_instruction() -> String:
	return "Check one shot {one_shot} on {node}"

func tick(delta:float) -> Status:
	var target : AnimationTree = _resolve_node(get("node")) as AnimationTree
	if target == null:
		push_error("\"%s\" couldn't resolve AnimationTree" % resource_name)
		return Status.FAILURE

	if target.get("parameters/%s/active" % get("one_shot")):
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AnimationTree", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("one_shot", &"")

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Active",
		"Inactive"
	])
