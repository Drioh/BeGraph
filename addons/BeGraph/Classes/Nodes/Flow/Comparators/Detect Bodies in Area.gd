@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Area Detect"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {area} (an Area2D/3D) is currently overlapping any physics body, branching to 'Body detected' or 'No body detected'.\n\nFails if {area} can't be resolved."

var _area : Node
var first_time : bool = true

func set_instruction() -> String:
	return "Check bodies overlapping {area}"

func tick() -> Status:
	if first_time:
		_area = _resolve_node(get("area"))
		if _area == null:
			push_error("\"%s\" couldn't resolve area" % resource_name)
			return Status.FAILURE
		first_time = false

	var bodies : Array = _area.get_overlapping_bodies()
	if bodies.size() > 0:
		tick_condition(0)
	else:
		tick_condition(1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("area", NodePath(""))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Body detected",
		"No body detected"
	])
