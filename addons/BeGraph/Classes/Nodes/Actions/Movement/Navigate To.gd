@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Navigate To"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var nav_agent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 150.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var avoidance_enabled : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var recalculation_interval : float = 0.5

var _node_ref : Node
var _agent_ref : Node
var _target_node : Node = null
var _target_point : Vector3 = Vector3.ZERO
var _is_dynamic : bool = false
var _safe_velocity : Vector3 = Vector3.ZERO
var _time_since_recalc : float = 0.0

func on_start() -> void:
	_time_since_recalc = 0.0
	_safe_velocity = Vector3.ZERO
	_node_ref = _resolve_node(eval(&"node"))
	_agent_ref = _resolve_node(eval(&"nav_agent"))
	
	if _node_ref == null or _agent_ref == null:
		abort("couldn't resolve node or navigation agent")
		return
		
	if not _setup_target():
		abort("invalid target position or node")
		return
		
	var avoidance : bool = eval(&"avoidance_enabled") as bool
	_agent_ref.set("avoidance_enabled", avoidance)
	if avoidance and not _agent_ref.velocity_computed.is_connected(_on_velocity_computed):
		_agent_ref.velocity_computed.connect(_on_velocity_computed)
		
	_update_target_position()

func tick(delta: float) -> Status:
	if _agent_ref.is_navigation_finished():
		return tick_next(delta)
		
	if _is_dynamic:
		_time_since_recalc += delta
		if _time_since_recalc >= (eval(&"recalculation_interval") as float):
			_update_target_position()
			_time_since_recalc = 0.0
			
	var avoidance : bool = eval(&"avoidance_enabled") as bool
	var next_pos : Vector3 = _to_vector3(_agent_ref.get_next_path_position())
	var current : Vector3 = _get_position(_node_ref)
	var spd : float = eval(&"speed") as float
	
	if avoidance:
		var desired : Vector3 = current.direction_to(next_pos) * spd
		_agent_ref.set_velocity(desired if _agent_ref is NavigationAgent3D else Vector2(desired.x, desired.y))
		_set_position(_node_ref, current + _safe_velocity * delta)
	else:
		_set_position(_node_ref, current.move_toward(next_pos, spd * delta))
		
	return Status.RUNNING

func _setup_target() -> bool:
	var value : Variant = eval(&"target")
	if value is NodePath and value != NodePath(""):
		_target_node = _resolve_node(value)
		_is_dynamic = _target_node != null
		return _is_dynamic
	if value is Vector2:
		_target_point = Vector3(value.x, value.y, 0)
		_is_dynamic = false
		return true
	if value is Vector3:
		_target_point = value
		_is_dynamic = false
		return true
	return false

func _update_target_position() -> void:
	var t : Vector3 = _get_position(_target_node) if _is_dynamic else _target_point
	_agent_ref.target_position = t if _agent_ref is NavigationAgent3D else Vector2(t.x, t.y)

func _on_velocity_computed(safe_vel) -> void:
	_safe_velocity = _to_vector3(safe_vel)

func _to_vector3(v) -> Vector3:
	return Vector3(v.x, v.y, 0) if v is Vector2 else v

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func on_end(_status: Status) -> void:
	if _agent_ref != null and is_instance_valid(_agent_ref):
		if _agent_ref.velocity_computed.is_connected(_on_velocity_computed):
			_agent_ref.velocity_computed.disconnect(_on_velocity_computed)

func set_instruction() -> String: return "Navigate {node} (agent {nav_agent}) to {target} at speed {speed} (avoidance: {avoidance_enabled})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
