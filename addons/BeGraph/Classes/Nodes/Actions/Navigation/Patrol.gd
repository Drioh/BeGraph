@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Patrol"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Patrols the children of {waypoints} (a container node) in sequence (Loop, PingPong, or Once) with an optional wait time at each point.\n\nEach direct Node2D/Node3D child of {waypoints}, in sibling order, is treated as one waypoint position."

enum Mode { ONCE, LOOP, PING_PONG, PING_PONG_LOOP}

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var waypoints : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Once,Loop,Ping Pong,Ping Pong (Loop)") var mode : Mode = Mode.ONCE
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var wait_time : float = 0.0

var _node_ref : Node
var _points : Array[Node] = []
var _current_index : int = 0
var _direction : int = 1
var _wait_left : float = 0.0
var _waiting : bool = false

func on_start() -> void:
	_node_ref = eval(&"node", true)
	if _node_ref == null:
		abort("couldn't resolve node to patrol")
		return

	var container : Node = eval(&"waypoints", true)
	if container == null:
		abort("couldn't resolve waypoints container")
		return

	_points.clear()
	for child in container.get_children():
		if child is Node2D or child is Node3D:
			_points.append(child)

	if _points.is_empty():
		abort("waypoints container has no Node2D/Node3D children")
		return

	_current_index = 0
	_direction = 1
	_waiting = false

func tick(delta: float) -> Status:
	if _node_ref == null or not is_instance_valid(_node_ref):
		return Status.FAILURE
	if _points.is_empty():
		return Status.FAILURE
	if not is_instance_valid(_points[_current_index]):
		return abort("waypoint at index %d was freed" % _current_index)

	if _waiting:
		_wait_left -= delta
		if _wait_left > 0.0:
			return Status.RUNNING
		_waiting = false
		return _advance_next(delta)

	var target_pos : Vector3 = _get_position(_points[_current_index])
	var curr_pos : Vector3 = _get_position(_node_ref)
	var max_step : float = (eval(&"speed") as float) * delta

	if curr_pos.distance_to(target_pos) <= max_step or curr_pos.distance_to(target_pos) <= 0.001:
		_set_position(_node_ref, target_pos)
		var wait_s : float = eval(&"wait_time") as float
		if wait_s > 0.0:
			_waiting = true
			_wait_left = wait_s
			return Status.RUNNING
		return _advance_next(delta)

	_set_position(_node_ref, curr_pos.move_toward(target_pos, max_step))
	return Status.RUNNING

func _advance_next(_delta: float) -> Status:
	var count : int = _points.size()

	match eval(&"mode") as Mode:
		Mode.ONCE:
			_current_index += 1
			if _current_index >= count:
				return Status.SUCCESS
		Mode.LOOP:
			_current_index = (_current_index + 1) % count
		Mode.PING_PONG:
			_current_index += _direction
			if _current_index >= count:
				_current_index = maxi(0, count - 2)
				_direction = -1
			elif _current_index < 0:
				return Status.SUCCESS
		Mode.PING_PONG_LOOP:
			_current_index += _direction
			if _current_index >= count:
				_current_index = maxi(0, count - 2)
				_direction = -1
			elif _current_index < 0:
				_current_index = mini(1, count - 1)
				_direction = 1

	return Status.RUNNING

func on_end(_status: Status) -> void:
	_node_ref = null
	_points.clear()

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func set_instruction() -> String: return "Patrol {node} between {waypoints}'s children ({mode}, speed {speed})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
