@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Apply Impulse"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Applies {impulse} as an instantaneous impulse to {node} (a RigidBody2D/3D), e.g. for knockback or explosions. For a RigidBody2D, only the X/Y components are used.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a rigid body."

func set_instruction() -> String:
	return "Apply impulse {impulse} to {node}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_rigid_body(target):
		push_error("\"%s\" couldn't resolve a rigid body" % resource_name)
		return Status.FAILURE

	var impulse : Vector3 = get("impulse")
	if target is RigidBody2D:
		target.apply_impulse(Vector2(impulse.x, impulse.y))
	else:
		target.apply_impulse(impulse)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "RigidBody2D,RigidBody3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("impulse", Vector3.ZERO)

## Returns [code]true[/code] if [param n] is a rigid body this node supports.
func _is_rigid_body(n: Node) -> bool:
	return n is RigidBody2D or n is RigidBody3D
