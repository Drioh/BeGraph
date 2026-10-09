@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Rigid Body Frozen"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"RigidBody2D,RigidBody3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not (target is RigidBody2D or target is RigidBody3D):
		return abort("couldn't resolve rigid body")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.freeze = true
		Mode.OFF: target.freeze = false
		Mode.TOGGLE: target.freeze = not target.freeze
		
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s freeze: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
