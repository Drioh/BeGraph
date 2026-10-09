@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Animation Tree Parameter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationTree") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parameter : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node")) as AnimationTree
	if target == null:
		return abort("couldn't resolve AnimationTree")
		
	target.set(eval(&"parameter"), eval(&"value"))
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s {parameter} to {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
