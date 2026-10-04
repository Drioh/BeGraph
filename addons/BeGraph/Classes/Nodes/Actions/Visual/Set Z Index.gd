@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Z Index"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the z_index of {node} (a CanvasItem) to {z_index}, or adds {z_index} to its current one, depending on {mode}. The value is clamped to the engine's range (-4096..4096).\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a CanvasItem."

enum Mode { SET, ADD }

func set_instruction() -> String:
	return "{mode} {node}'s z_index: {z_index}"

func tick(delta:float) -> Status:
	var target : CanvasItem = _resolve_node(get("node")) as CanvasItem
	if target == null:
		push_error("\"%s\" couldn't resolve a CanvasItem" % resource_name)
		return Status.FAILURE

	var value : int = get("z_index")
	if get("mode") == Mode.ADD:
		value += target.z_index
	target.z_index = clampi(value, RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CanvasItem", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Set,Add")
	_add_behavior_property("z_index", int(0))
