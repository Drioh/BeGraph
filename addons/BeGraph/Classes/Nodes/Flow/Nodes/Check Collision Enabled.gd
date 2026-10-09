@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Collision Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY +"CollisionShape2D,CollisionShape3D,CollisionPolygon2D,CollisionPolygon3D") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target : Node = _resolve_node(eval(&"node"))
	if target == null or not _is_collision_owner(target):
		return abort("couldn't resolve collision shape/polygon")
		
	tick_condition(delta, 0 if not target.disabled else 1)
	return Status.RUNNING

func _is_collision_owner(n: Node) -> bool:
	return n is CollisionShape2D or n is CollisionShape3D or n is CollisionPolygon2D or n is CollisionPolygon3D

func set_instruction() -> String: return "Check {node}'s collision state"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Enabled", "Disabled"])
