@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Field Of View"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {target} lies inside the view cone of {node}: within {angle} degrees (total opening) around the direction chosen in {forward} (relative to {node}'s rotation) and, if {max_distance} is greater than 0, closer than {max_distance}.\n\nBranches to 'Target in view' or 'Target out of view'. It only checks geometry: combine it with 'Line Of Sight' to also check for obstacles.\n\nFails if {node} or {target} can't be resolved."

enum Forward { POS_X, NEG_X, POS_Y, NEG_Y, POS_Z, NEG_Z }

var _node : Node

func set_instruction() -> String:
	return "Is {target} in {node}'s view ({angle} deg, max {max_distance})"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_node):
		_node = _resolve_node(get("node"))
		if _node == null:
			push_error("\"%s\" couldn't resolve node" % resource_name)
			return Status.FAILURE
		dirty = false

	var target : Node = _resolve_node(get("target"))
	if target == null:
		push_error("\"%s\" couldn't resolve target" % resource_name)
		return Status.FAILURE

	var to_target : Vector3 = _get_position(target) - _get_position(_node)
	var distance : float = to_target.length()
	var max_distance : float = get("max_distance")

	var in_view : bool = true
	if max_distance > 0.0 and distance > max_distance:
		in_view = false
	elif distance > 0.0:
		var half_angle : float = deg_to_rad(get("angle")) * 0.5
		in_view = _forward_vector().angle_to(to_target) <= half_angle

	tick_condition(delta, 0 if in_view else 1)
	return Status.RUNNING

func _forward_vector() -> Vector3:
	var local : Vector3
	match get("forward"):
		Forward.POS_X: local = Vector3.RIGHT
		Forward.NEG_X: local = Vector3.LEFT
		Forward.POS_Y: local = Vector3.UP
		Forward.NEG_Y: local = Vector3.DOWN
		Forward.POS_Z: local = Vector3.BACK
		_: local = Vector3.FORWARD

	if _node is Node2D:
		var v : Vector2 = _node.global_transform.basis_xform(Vector2(local.x, local.y))
		return Vector3(v.x, v.y, 0.0).normalized()
	if _node is Node3D:
		return (_node.global_transform.basis * local).normalized()
	return local

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("target", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("angle", float(90.0))
	_add_behavior_property("max_distance", float(0.0))
	_add_behavior_property("forward", 0, PROPERTY_HINT_ENUM, "+X (2D right),-X (2D left),+Y (2D down),-Y (2D up),+Z (3D back),-Z (3D forward)")

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Target in view",
		"Target out of view"
	])

#region Helpers (self-contained copies, no external dependency)

## Global position of [param n] (Node2D or Node3D) as [Vector3]; z is 0 for 2D nodes.
func _get_position(n: Node) -> Vector3:
	if n is Node2D:
		var p : Vector2 = n.global_position
		return Vector3(p.x, p.y, 0.0)
	if n is Node3D:
		return n.global_position
	return Vector3.ZERO

#endregion
