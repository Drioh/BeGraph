@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Camera Current"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a Camera2D/3D) is the currently active camera in its viewport, branching to 'Current' or 'Not current'.\n\nFails if {node} can't be resolved or isn't a camera."

func set_instruction() -> String:
	return "Check if {node} is current"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	var is_camera : bool = target is Camera2D or target is Camera3D
	if target == null or not is_camera:
		push_error("\"%s\" couldn't resolve a camera" % resource_name)
		return Status.FAILURE
	
	var condition = target.is_current() if target is Camera2D else target.current
	if condition:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Camera2D,Camera3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Current",
		"Not current"
	])
