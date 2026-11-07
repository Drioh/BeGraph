@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Velocity"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether the linear speed of a CharacterBody or RigidBody exceeds a threshold along the selected axis."

enum Axis { TOTAL, HORIZONTAL, VERTICAL }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Total,Horizontal,Vertical") var axis : Axis = Axis.TOTAL
@export_custom(BG.HINT_NONE, BG.PROPERTY) var threshold : float = 10.0

var _target : Node = null

func on_start() -> void:
	_target = eval(&"node", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true)

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target):
		return abort("couldn't resolve node")
		
	var speed : float = _speed_of(_target)
	if speed < 0.0:
		return abort("unsupported body type")
		
	return tick_condition(delta, 0 if speed > (eval(&"threshold") as float) else 1)

func on_end(_status: Status) -> void:
	_target = null

func _speed_of(n : Node) -> float:
	var v : Variant
	if n is CharacterBody2D or n is CharacterBody3D: v = n.velocity
	elif n is RigidBody2D or n is RigidBody3D: v = n.linear_velocity
	else: return -1.0
	
	match eval(&"axis") as Axis:
		Axis.HORIZONTAL:
			return absf(v.x) if v is Vector2 else Vector2(v.x, v.z).length()
		Axis.VERTICAL:
			return absf(v.y)
		_:
			return v.length()

func set_instruction() -> String: return "Check {node}'s {axis} speed vs {threshold}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["speed > {threshold}", "speed <= {threshold}"])
