@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Visible"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Turns {node} (a CanvasItem or Node3D) on, off, or toggles it, depending on {mode}, by setting its visibility.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a visual node."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Set {node}'s visibility: {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_visual(target):
		push_error("\"%s\" couldn't resolve a visual node" % resource_name)
		return Status.FAILURE

	match get("mode"):
		Mode.ON:
			target.visible = true
		Mode.OFF:
			target.visible = false
		Mode.TOGGLE:
			target.visible = not target.visible

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CanvasItem,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")

## Returns [code]true[/code] if [param n] exposes a "visible" property.
func _is_visual(n: Node) -> bool:
	return n is CanvasItem or n is Node3D
