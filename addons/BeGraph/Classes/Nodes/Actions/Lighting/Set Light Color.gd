@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Light Color"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets {node}'s (a Light2D or Light3D) color to {color}, using whichever property applies (Light2D's \"color\" or Light3D's \"light_color\") automatically.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a light."

func set_instruction() -> String:
	return "Set {node}'s color to {color}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_light(target):
		push_error("\"%s\" couldn't resolve a light" % resource_name)
		return Status.FAILURE

	var property_name : String = "color" if target is Light2D else "light_color"
	target.set(property_name, get("color"))

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Light2D,Light3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("color", Color.WHITE)

## Returns [code]true[/code] if [param n] is a light node this node supports.
func _is_light(n: Node) -> bool:
	return n is Light2D or n is Light3D
