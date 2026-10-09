@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Visible"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE,BG.PROPERTY+ "CanvasItem,Node3D" ) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not (target is CanvasItem or target is Node3D):
		return abort("couldn't resolve visual node")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.visible = true
		Mode.OFF: target.visible = false
		Mode.TOGGLE: target.visible = not target.visible
		
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s visibility: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
