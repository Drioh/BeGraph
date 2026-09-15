@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Patrol"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { SPEED, DURATION }

var _index : int = 0
var _start_time : int = -1
var _start_position : Vector3

func set_instruction() -> String:
	return "Patrol {node} between {points}(mode: {mode})"

func tick() -> Status:
	var points : Array = get("points")
	if points.is_empty():
		return Status.FAILURE

	var node : Node = _resolve_node(get("node"))
	if node == null:
		push_error("\"%s\" couldn't resolve node to move" % resource_name)
		return Status.FAILURE
	

	var destination : Vector3 
	if points[_index] is not Vector3:
		if points[_index] is Node3D:
			destination = points[_index].position
		elif points[_index] is Node2D:
			destination = Vector3(points[_index].position.x,points[_index].position.y,0)
	else:
		destination = points[_index]
	if _start_time == -1:
		_start_time = Time.get_ticks_msec()
		_start_position = _get_position(node)

	var t : float = _progress(_start_position, destination)
	print("sono t: %s"%t)
	_set_position(node, _start_position.lerp(destination, t))

	if t < 1.0:
		return Status.RUNNING

	_start_time = -1
	_index += 1
	if _index >= points.size():
		if not get("loop"):
			_index = points.size() - 1
			return Status.SUCCESS
		_index = 0
	return Status.RUNNING

func _progress(from : Vector3, to : Vector3) -> float:
	var elapsed : float = (Time.get_ticks_msec() - _start_time) / 1000.0
	if get("mode") == Mode.SPEED:
		var total_distance : float = from.distance_to(to)
		return 1.0 if total_distance == 0.0 else clamp((get("speed") * elapsed) / total_distance, 0.0, 1.0)
	var duration : float = get("duration")
	return 1.0 if duration <= 0.0 else clamp(elapsed / duration, 0.0, 1.0)

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
	_add_behavior_property("node", NodePath(""),PROPERTY_HINT_NODE_TYPE,"Node2D,Node3D","","",PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT )
	_add_behavior_property("points", [])
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Speed,Duration")
	_add_behavior_property("speed", float(100.0))
	_add_behavior_property("duration", float(1.0))
	_add_behavior_property("loop", true)
