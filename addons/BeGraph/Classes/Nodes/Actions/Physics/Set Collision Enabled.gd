@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Collision Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Enables {node} (a CollisionShape2D/3D or CollisionPolygon2D/3D), disables it, or toggles it, depending on {mode} - handy for turning hitboxes/hurtboxes on and off.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a collision shape/polygon."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Set {node}'s collision: {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_collision_owner(target):
		push_error("\"%s\" couldn't resolve a collision shape/polygon" % resource_name)
		return Status.FAILURE

	match get("mode"):
		Mode.ON:
			target.disabled = false
		Mode.OFF:
			target.disabled = true
		Mode.TOGGLE:
			target.disabled = not target.disabled

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CollisionShape2D,CollisionShape3D,CollisionPolygon2D,CollisionPolygon3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")

## Returns [code]true[/code] if [param n] is a collision shape/polygon this node supports.
func _is_collision_owner(n: Node) -> bool:
	return n is CollisionShape2D or n is CollisionShape3D or n is CollisionPolygon2D or n is CollisionPolygon3D
