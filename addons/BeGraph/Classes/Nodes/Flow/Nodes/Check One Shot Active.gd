@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check One Shot Active"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "AnimationTree") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var one_shot : StringName = &""

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node")) as AnimationTree
	if target == null:
		return abort("couldn't resolve AnimationTree")
		
	var is_act : bool = bool(target.get("parameters/%s/active" % eval(&"one_shot")))
	tick_condition(delta, 0 if is_act else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check one shot {one_shot} on {node}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Active", "Inactive"])
