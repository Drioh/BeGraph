@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Visible"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a CanvasItem or Node3D) is currently visible, branching to 'Visible' or 'Hidden'.\n\nFails if {node} can't be resolved or isn't a visual node."

func set_instruction() -> String:
	return "Check {node}'s visibility"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_visual(target):
		push_error("\"%s\" couldn't resolve a visual node" % resource_name)
		return Status.FAILURE

	if target.visible:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CanvasItem,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Visible",
		"Hidden"
	])

## Returns [code]true[/code] if [param n] exposes a "visible" property.
func _is_visual(n: Node) -> bool:
	return n is CanvasItem or n is Node3D
