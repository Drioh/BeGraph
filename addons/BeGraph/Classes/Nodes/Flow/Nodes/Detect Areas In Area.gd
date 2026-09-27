@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Detect Areas In Area"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {area} (an Area2D/3D) is currently overlapping any other Area, branching to 'Area detected' or 'No area detected'.\n\nSibling of \"Area Detect\", which checks physics bodies instead.\n\nFails if {area} can't be resolved."

var _area : Node

func set_instruction() -> String:
	return "Check areas overlapping {area}"

func tick(delta:float) -> Status:
	if dirty:
		_area = _resolve_node(get("area"))
		if _area == null:
			push_error("\"%s\" couldn't resolve area" % resource_name)
			return Status.FAILURE
		dirty = false

	var areas : Array = _area.get_overlapping_areas()
	if areas.size() > 0:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("area", NodePath(""))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Area detected",
		"No area detected"
	])
