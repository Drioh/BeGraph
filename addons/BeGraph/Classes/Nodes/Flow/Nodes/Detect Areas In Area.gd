@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Detect Areas In Area"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether any areas are currently overlapping an Area2D or Area3D node."

@export_custom(BG.HINT_NONE, BG.PROPERTY+"Area2D,Area3D") var area : NodePath = NodePath("")

var _area : Node = null

func on_start() -> void:
	_area = eval(&"area", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"area"):
		_area = eval(&"area", true)

func tick(delta: float) -> Status:
	if _area == null or not is_instance_valid(_area) or not (_area is Area2D or _area is Area3D):
		return abort("couldn't resolve area")
		
	var areas : Array = _area.get_overlapping_areas()
	return tick_condition(delta, 0 if areas.size() > 0 else 1)

func on_end(_status: Status) -> void:
	_area = null

func set_instruction() -> String: return "Check areas overlapping {area}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Area detected", "No area detected"])
