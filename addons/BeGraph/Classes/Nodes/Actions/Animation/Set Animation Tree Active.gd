@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Animation Tree Active"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationTree") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node")) as AnimationTree
	if target == null:
		return abort("couldn't resolve AnimationTree")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.active = true
		Mode.OFF: target.active = false
		Mode.TOGGLE: target.active = not target.active
		
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s tree: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
