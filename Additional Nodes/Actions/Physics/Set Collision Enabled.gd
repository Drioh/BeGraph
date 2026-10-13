@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Collision Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Enables, disables, or toggles collision shape or polygon disabled state."

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "CollisionShape2D,CollisionShape3D,CollisionPolygon2D,CollisionPolygon3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+ "On,Off,Toggle") var mode : Mode = Mode.ON

func tick(_delta: float) -> Status:
	var target :Node= eval(&"node", true)
	if target == null or not _is_collision_owner(target):
		return abort("couldn't resolve collision shape/polygon")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.disabled = false
		Mode.OFF: target.disabled = true
		Mode.TOGGLE: target.disabled = not target.disabled
		
	return Status.SUCCESS

func _is_collision_owner(n: Node) -> bool:
	return n is CollisionShape2D or n is CollisionShape3D or n is CollisionPolygon2D or n is CollisionPolygon3D

func set_instruction() -> String: return "Set {node}'s collision: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
