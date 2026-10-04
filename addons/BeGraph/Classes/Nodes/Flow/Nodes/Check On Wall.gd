@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check On Wall"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a CharacterBody2D/3D) is currently touching the wall (is_on_wall()), branching to 'On wall' or 'Not on wall'.\n\nFails if {node} can't be resolved or isn't a character body."

func set_instruction() -> String:
	return "Check if {node} is on wall"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_character_body(target):
		push_error("\"%s\" couldn't resolve a character body" % resource_name)
		return Status.FAILURE

	if target.is_on_wall():
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CharacterBody2D,CharacterBody3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"On wall",
		"Not on wall"
	])

## Returns [code]true[/code] if [param n] is a character body this node supports.
func _is_character_body(n: Node) -> bool:
	return n is CharacterBody2D or n is CharacterBody3D
