@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Animation Tree Active"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Turns {node} (an AnimationTree) on, off, or toggles it, depending on {mode}.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't an AnimationTree."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Set {node}'s tree: {mode}"

func tick(delta:float) -> Status:
	var target : AnimationTree = _resolve_node(get("node")) as AnimationTree
	if target == null:
		push_error("\"%s\" couldn't resolve AnimationTree" % resource_name)
		return Status.FAILURE

	match get("mode"):
		Mode.ON:
			target.active = true
		Mode.OFF:
			target.active = false
		Mode.TOGGLE:
			target.active = not target.active

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AnimationTree", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")
