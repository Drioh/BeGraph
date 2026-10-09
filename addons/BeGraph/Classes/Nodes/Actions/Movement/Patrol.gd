@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Patrol"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { SPEED, DURATION }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var points : Array = []
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Speed,Duration") var mode : Mode = Mode.SPEED
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var loop : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var calculate_destination_each_frame : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var time_to_wait_upon_reaching_destination : float = 0.0

var _node_ref : Node
var _resolved_points : Array = []
var _index : int = 0
var _current_dest : Vector3 = Vector3.ZERO
var _elapsed : float = 0.0
var _waiting : bool = false
var _wait_elapsed : float = 0.0

func on_start() -> void:
	_index = 0
	_elapsed = 0.0
	_waiting = false
	_wait_elapsed = 0.0
	_resolved_points.clear()
	
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node to patrol")
		return
		
	var pts : Array = eval(&"points") as Array
	for p in pts:
		var res = _resolve_node(p)
		_resolved_points.append(res if res != null else p)
		
	if _resolved_points.is_empty():
		abort("no patrol points provided")
		return
		
	_calculate_dest()

func tick(delta: float) -> Status:
	var wait_t : float = eval(&"time_to_wait_upon_reaching_destination") as float
	if _waiting:
		_wait_elapsed += delta
		if _wait_elapsed < wait_t:
			return Status.RUNNING
		_waiting = false
		_wait_elapsed = 0.0
		return _advance_next(delta)
		
	_elapsed += delta
	if eval(&"calculate_destination_each_frame"):
		_calculate_dest()
		
	var dist_rem : float = _node_ref.global_position.distance_to(_current_dest)
	if dist_rem <= 0.001:
		_node_ref.global_position = _current_dest
		_elapsed = 0.0
		if wait_t > 0.0:
			_waiting = true
			_wait_elapsed = 0.0
			return Status.RUNNING
		return _advance_next(delta)
		
	var move_amt : float = 0.0
	if (eval(&"mode") as Mode) == Mode.SPEED:
		move_amt = (eval(&"speed") as float) * delta
	else:
		var rem_t : float = (eval(&"duration") as float) - _elapsed
		if rem_t <= 0.0:
			_node_ref.global_position = _current_dest
			return _advance_next(delta)
		move_amt = (dist_rem / rem_t) * delta
		
	_node_ref.global_position = _node_ref.global_position.move_toward(_current_dest, move_amt)
	return Status.RUNNING

func _advance_next(delta: float) -> Status:
	_index += 1
	if _index >= _resolved_points.size():
		if not eval(&"loop"):
			_index = _resolved_points.size() - 1
			return tick_next(delta)
		_index = 0
	_calculate_dest()
	return Status.RUNNING

func _calculate_dest() -> void:
	var item = _resolved_points[_index]
	if item is Node2D or item is Node3D:
		_current_dest = item.global_position
	elif item is Vector3:
		_current_dest = item
	elif item is Vector2:
		_current_dest = Vector3(item.x, item.y, 0)

func set_instruction() -> String: return "Patrol {node} between {points} (mode: {mode})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
