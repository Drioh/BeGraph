@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Animation Tree Active"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationTree") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node")) as AnimationTree
	if target == null:
		return abort("couldn't resolve AnimationTree")
		
	tick_condition(delta, 0 if target.active else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check {node}'s active state"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Active", "Inactive"])
