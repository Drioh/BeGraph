@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Camera Current"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Camera2D,Camera3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM,BG.PROPERTY+ "On,Off,Toggle") var mode : Mode = Mode.ON

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not (target is Camera2D or target is Camera3D):
		return abort("couldn't resolve camera node")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.make_current()
		Mode.OFF:
			if target is Camera3D: target.current = false
			else: return abort("Camera2D requires another Camera2D to be made current in its stead")
		Mode.TOGGLE:
			if target is Camera2D:
				if not target.is_current(): target.make_current()
				else: return abort("Camera2D requires another Camera2D to be made current in its stead")
			else:
				target.current = not target.current
				
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s current: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
