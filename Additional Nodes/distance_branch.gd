@tool
extends BehaviorNode

const DISPLAY_NAME: String = "Distance Branch"
const DISPLAY_ICON: String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO: String = "Compares distance to target against a threshold and branches."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY + "Node2D") var actor: NodePath = NodePath("")
@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY + "Node2D") var target: NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var range_threshold: float = 200.0

func set_node_category() -> String:
	return "control_flow_node"

func set_input() -> bool:
	return true

## Multiple conditions force set_output() to false; each condition becomes its own output port.
func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Within Range (<= {range_threshold})",
		"Outside Range (> {range_threshold})"
	])

func set_instruction() -> String:
	return "Check distance from {actor} to {target}"

## Instruction displayed in node. To set this parameter, use the [method set_instruction] method:

func tick(delta: float) -> Status:
	var a_node := eval(&"actor", true) as Node2D
	var t_node := eval(&"target", true) as Node2D
	
	if a_node == null or t_node == null:
		return abort("Invalid actor or target node reference")
	
	var dist := a_node.global_position.distance_to(t_node.global_position)
	var threshold: float = eval(&"range_threshold")
	
	if dist <= threshold:
		# Tick the first condition slot (index 0: Within Range)
		return tick_condition(delta, 0)
	else:
		# Tick the second condition slot (index 1: Outside Range)
		return tick_condition(delta, 1)

func set_allows_multiple_outputs() -> bool: return false
