@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Line Of Sight"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Casts {raycast} (a RayCast2D/3D) towards {target} each tick, branching to 'Target visible' if it hits {target} (or a descendant) unobstructed, otherwise to 'Target obstructed / out of range'.\n\nFails if {raycast} or {target} can't be resolved."

var _raycast : Node
var _target : Node

func set_instruction() -> String:
	return "Line of sight from {raycast} to {target}"

func tick() -> Status:
	if dirty:
		_raycast = _resolve_node(get("raycast"))
		_target = _resolve_node(get("target"))
		if _raycast == null or _target == null:
			push_error("\"%s\" couldn't resolve raycast or target" % resource_name)
			return Status.FAILURE
		_raycast.enabled = true
		dirty = false

	_raycast.target_position = _raycast.to_local(_target.global_position)
	_raycast.force_raycast_update()

	if not _raycast.is_colliding():
		tick_condition(1) # fuori portata / nessun ostacolo intercettato
		return Status.RUNNING

	var collider : Object = _raycast.get_collider()
	if collider == _target or (collider is Node and _target.is_ancestor_of(collider)):
		tick_condition(0)
	else:
		tick_condition(1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("raycast", NodePath(""))
	_add_behavior_property("target", NodePath(""))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Target visible",
		"Target obstructed / out of range"
	])
