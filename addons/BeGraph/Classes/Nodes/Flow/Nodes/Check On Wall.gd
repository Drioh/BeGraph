@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check On Wall"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CharacterBody2D,CharacterBody3D") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not (target is CharacterBody2D or target is CharacterBody3D):
		return abort("couldn't resolve character body")
		
	tick_condition(delta, 0 if target.is_on_wall() else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check if {node} is on wall"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["On wall", "Not on wall"])
