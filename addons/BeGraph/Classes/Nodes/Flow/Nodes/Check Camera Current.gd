@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Camera Current"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "Camera2D,Camera3D") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target : Node = _resolve_node(eval(&"node"))
	if target == null or not (target is Camera2D or target is Camera3D):
		return abort("couldn't resolve camera")
		
	var is_curr : bool = target.is_current() if target is Camera2D else target.current
	tick_condition(delta, 0 if is_curr else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check if {node} is current"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Current", "Not current"])
