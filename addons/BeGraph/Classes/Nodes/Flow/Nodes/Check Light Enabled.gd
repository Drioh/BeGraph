@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Light Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a Light2D or Light3D) is currently on (visible), branching to 'On' or 'Off'.\n\nFails if {node} can't be resolved or isn't a light."

func set_instruction() -> String:
	return "Check {node}'s light state"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_light(target):
		push_error("\"%s\" couldn't resolve a light" % resource_name)
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
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Light2D,Light3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"On",
		"Off"
	])

## Returns [code]true[/code] if [param n] is a light node this node supports.
func _is_light(n: Node) -> bool:
	return n is Light2D or n is Light3D
