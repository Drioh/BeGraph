@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Collision Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether a collision shape or polygon node is enabled (not disabled)."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CollisionShape2D,CollisionShape3D,CollisionPolygon2D,CollisionPolygon3D") var node : NodePath = NodePath("")

var _target : Node = null

func on_start() -> void:
	_target = eval(&"node", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true)

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target) or not _is_collision_shape(_target):
		return abort("couldn't resolve collision shape/polygon")
		
	return tick_condition(delta, 0 if not _target.disabled else 1)

func on_end(_status: Status) -> void:
	_target = null

func _is_collision_shape(n: Node) -> bool:
	return n is CollisionShape2D or n is CollisionShape3D or n is CollisionPolygon2D or n is CollisionPolygon3D

func set_instruction() -> String: return "Check {node}'s collision state"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Enabled", "Disabled"])
