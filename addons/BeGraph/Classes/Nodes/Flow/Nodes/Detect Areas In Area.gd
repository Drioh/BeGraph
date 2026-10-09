@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Detect Areas In Area"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"Area2D,Area3D") var area : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"area"))
	if target == null or not (target is Area2D or target is Area3D):
		return abort("couldn't resolve area")
		
	var areas : Array = target.get_overlapping_areas()
	tick_condition(delta, 0 if areas.size() > 0 else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check areas overlapping {area}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Area detected", "No area detected"])
