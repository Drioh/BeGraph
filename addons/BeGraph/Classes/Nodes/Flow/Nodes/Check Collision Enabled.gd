@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Collision Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a CollisionShape2D/3D or CollisionPolygon2D/3D) is currently enabled, branching to 'Enabled' or 'Disabled'.\n\nFails if {node} can't be resolved or isn't a collision shape/polygon."

func set_instruction() -> String:
	return "Check {node}'s collision state"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_collision_owner(target):
		push_error("\"%s\" couldn't resolve a collision shape/polygon" % resource_name)
		return Status.FAILURE

	if not target.disabled:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CollisionShape2D,CollisionShape3D,CollisionPolygon2D,CollisionPolygon3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Enabled",
		"Disabled"
	])

## Returns [code]true[/code] if [param n] is a collision shape/polygon this node supports.
func _is_collision_owner(n: Node) -> bool:
	return n is CollisionShape2D or n is CollisionShape3D or n is CollisionPolygon2D or n is CollisionPolygon3D
