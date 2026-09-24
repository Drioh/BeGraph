@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Navigate To"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Drives {node} towards {target} (Node, Vector2 or Vector3) using {nav_agent} (a NavigationAgent2D/3D) at {speed}, with optional avoidance ({avoidance_enabled}) and periodic re-targeting every {recalculation_interval}s (this allows for dynamic targets).\n\nReturns RUNNING while navigating and SUCCESS once the agent reports it has arrived; fails if {node}/{nav_agent} can't be resolved or {target} is invalid."

var _node : Node
var _agent : Node
var _target_node : Node = null
var _target_point : Vector3 = Vector3.ZERO
var _is_dynamic_target : bool = false
var _safe_velocity : Vector3 = Vector3.ZERO
var _time_since_recalc : float = 0.0

func set_instruction() -> String:
	return "Navigate {node} (agent {nav_agent}) to {target} at speed {speed} (avoidance: {avoidance_enabled})"

func tick(delta:float) -> Status:
	if dirty:
		_node = _resolve_node(get("node"))
		_agent = _resolve_node(get("nav_agent"))
		if _node == null or _agent == null:
			push_error("\"%s\" couldn't resolve node or navigation agent" % resource_name)
			return Status.FAILURE

		if not _setup_target():
			push_error("\"%s\" has no valid target (expected a NodePath, Vector2 or Vector3)" % resource_name)
			return Status.FAILURE

		_agent.avoidance_enabled = get("avoidance_enabled")
		if _agent.avoidance_enabled and not _agent.velocity_computed.is_connected(_on_velocity_computed):
			_agent.velocity_computed.connect(_on_velocity_computed)

		_update_agent_target()
		_safe_velocity = Vector3.ZERO
		_time_since_recalc = 0.0
	dirty = false

	if _agent.is_navigation_finished():
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	if _is_dynamic_target:
		_time_since_recalc += delta
		if _time_since_recalc >= get("recalculation_interval"):
			_update_agent_target()
			_time_since_recalc = 0.0

	var avoidance : bool = get("avoidance_enabled")
	if avoidance != _agent.avoidance_enabled:
		_agent.avoidance_enabled = avoidance
		if avoidance and not _agent.velocity_computed.is_connected(_on_velocity_computed):
			_agent.velocity_computed.connect(_on_velocity_computed)

	var next_pos : Vector3 = _to_vector3(_agent.get_next_path_position())
	var current : Vector3 = _get_position(_node)
	var speed : float = get("speed")

	if avoidance:
		var desired : Vector3 = current.direction_to(next_pos) * speed
		_agent.set_velocity(desired if _agent is NavigationAgent3D else Vector2(desired.x, desired.y))
		_set_position(_node, current + _safe_velocity * delta)
	else:
		_set_position(_node, current.move_toward(next_pos, speed * delta))

	return Status.RUNNING

func _setup_target() -> bool:
	var value : Variant = get("target")
	if value is NodePath and value != NodePath(""):
		_target_node = _resolve_node(value)
		_is_dynamic_target = _target_node != null
		return _is_dynamic_target
	if value is Vector2:
		_target_point = Vector3(value.x, value.y, 0)
		_is_dynamic_target = false
		return true
	if value is Vector3:
		_target_point = value
		_is_dynamic_target = false
		return true
	return false

func _update_agent_target() -> void:
	var t : Vector3 = _get_position(_target_node) if _is_dynamic_target else _target_point
	_agent.target_position = t if _agent is NavigationAgent3D else Vector2(t.x, t.y)

func _on_velocity_computed(safe_velocity) -> void:
	_safe_velocity = _to_vector3(safe_velocity)

func _to_vector3(v) -> Vector3:
	if v is Vector2:
		return Vector3(v.x, v.y, 0)
	return v

func _get_position(n : Node) -> Vector3:
	if n is Node2D:
		var p : Vector2 = n.global_position
		return Vector3(p.x, p.y, 0)
	if n is Node3D:
		return n.global_position
	return Vector3.ZERO

func _set_position(n : Node, pos : Vector3) -> void:
	if n is Node2D:
		n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D:
		n.global_position = pos

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("nav_agent", NodePath(""))
	_add_behavior_property("target", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("speed", float(150.0))
	_add_behavior_property("avoidance_enabled", false)
	_add_behavior_property("recalculation_interval", float(0.5))
