@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Animation Tree Parameter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes {value} into {node}'s (an AnimationTree) parameter at {parameter} - e.g. \"parameters/Blend2/blend_position\" or \"parameters/conditions/is_running\".\n\nSucceeds once applied; fails if {node} can't be resolved or isn't an AnimationTree."

func set_instruction() -> String:
	return "Set {node}'s {parameter} to {value}"

func tick(delta:float) -> Status:
	var target : AnimationTree = _resolve_node(get("node")) as AnimationTree
	if target == null:
		push_error("\"%s\" couldn't resolve AnimationTree" % resource_name)
		return Status.FAILURE

	target.set(get("parameter"), get("value"))
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AnimationTree", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("parameter", "")
	_add_behavior_property("value", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
