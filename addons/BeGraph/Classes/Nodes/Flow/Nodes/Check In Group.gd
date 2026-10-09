@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check In Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var group : StringName = &""

func tick(delta: float) -> Status:
	var target : Node = _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")
		
	var in_grp : bool = target.is_in_group(eval(&"group"))
	tick_condition(delta, 0 if in_grp else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check if {node} is in group {group}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["In group", "Not in group"])
