@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wander"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 200.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 80.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var wait_time : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var around_start : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var points_to_visit : int = 0

var _node_ref : Node
var _origin : Vector3 = Vector3.ZERO
var _destination : Vector3 = Vector3.ZERO
var _has_dest : bool = false
var _waiting : bool = false
var _wait_left : float = 0.0
var _visited : int = 0

func on_start() -> void:
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node to wander")
		return
		
	_origin = _get_position(_node_ref)
	_has_dest = false
	_waiting = false
	_visited = 0

func tick(delta: float) -> Status:
	if _waiting:
		_wait_left -= delta
		if _wait_left > 0.0:
			return Status.RUNNING
		_waiting = false
		
	if not _has_dest:
		_destination = _pick_destination()
		_has_dest = true
		
	var rem : float = _step_towards(_node_ref, _destination, (eval(&"speed") as float) * delta)
	if rem > 0.0:
		return Status.RUNNING
		
	_has_dest = false
	_visited += 1
	var limit : int = eval(&"points_to_visit") as int
	if limit > 0 and _visited >= limit:
		return tick_next(delta)
		
	_wait_left = eval(&"wait_time") as float
	_waiting = _wait_left > 0.0
	return Status.RUNNING

func _pick_destination() -> Vector3:
	var center : Vector3 = _origin if eval(&"around_start") else _get_position(_node_ref)
	var offset : Vector3 = _random_dir(_node_ref is Node3D) * sqrt(randf()) * (eval(&"radius") as float)
	return center + offset

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func _step_towards(n: Node, dest: Vector3, max_step: float) -> float:
	var curr : Vector3 = _get_position(n)
	var rem : float = curr.distance_to(dest)
	if rem <= max_step or rem <= 0.0001:
		_set_position(n, dest)
		return 0.0
	_set_position(n, curr.move_toward(dest, max_step))
	return rem - max_step

func _random_dir(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle)) if in_3d else Vector3(cos(angle), sin(angle), 0.0)

func set_instruction() -> String: return "Wander {node} within {radius} at speed {speed}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
