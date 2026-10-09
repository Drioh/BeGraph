@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Area Detect"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"Area2D,Area3D") var area : NodePath = NodePath("")

var _area : Node = null

func on_start() -> void:
	_area = _resolve_node(eval(&"area"))

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"area"):
		_area = _resolve_node(eval(&"area"))

func tick(delta: float) -> Status:
	if _area == null or not is_instance_valid(_area) or not (_area is Area2D or _area is Area3D):
		return abort("couldn't resolve area node")
		
	var bodies : Array = _area.get_overlapping_bodies()
	tick_condition(delta, 0 if bodies.size() > 0 else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check bodies overlapping {area}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Body detected", "No body detected"])
