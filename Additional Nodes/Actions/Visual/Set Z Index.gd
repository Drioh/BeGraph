@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Z Index"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets or offsets the z_index of a CanvasItem node."

enum Mode { SET, ADD }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CanvasItem" ) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Set,Add" ) var mode : Mode = Mode.SET
@export_custom(BG.HINT_NONE, BG.PROPERTY) var z_index : int = 0

func tick(_delta: float) -> Status:
	var target :CanvasItem= eval(&"node", true) as CanvasItem
	if target == null:
		return abort("couldn't resolve CanvasItem")
		
	var val : int = eval(&"z_index") as int
	if (eval(&"mode") as Mode) == Mode.ADD:
		val += target.z_index
		
	target.z_index = clampi(val, RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)
	return Status.SUCCESS

func set_instruction() -> String: return "{mode} {node}'s z_index: {z_index}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
