@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Velocity"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

enum Axis { TOTAL, HORIZONTAL, VERTICAL }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Total,Horizontal,Vertical") var axis : Axis = Axis.TOTAL
@export_custom(BG.HINT_NONE, BG.PROPERTY) var threshold : float = 10.0

func tick(delta: float) -> Status:
	var target : Node = _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")
		
	var speed : float = _speed_of(target)
	if speed < 0.0:
		return abort("unsupported body type")
		
	tick_condition(delta, 0 if speed > (eval(&"threshold") as float) else 1)
	return Status.RUNNING

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
