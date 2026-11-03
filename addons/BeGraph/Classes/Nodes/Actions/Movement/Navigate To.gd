@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Navigate To"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Navigates a node towards a target position using a NavigationAgent2D or NavigationAgent3D."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var navigation_agent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var target : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0

var _target_node : Node
var _node : Node
var _agent : Node

func on_start() -> void:
	_node = eval(&"node", true)
	_agent = eval(&"navigation_agent", true)
	_target_node = eval(&"target", true)

	if _node == null or _agent == null or not is_instance_valid(_node) or not is_instance_valid(_agent):
		abort("couldn't resolve node or navigation agent")
		return

	var target_pos : Variant = _resolve_target_pos()
	if target_pos == null:
		abort("invalid target position or node")
		return

	_agent.target_position = target_pos

func tick(delta: float) -> Status:
	if _node == null or _agent == null or not is_instance_valid(_node) or not is_instance_valid(_agent):
		return Status.FAILURE

	if _agent.is_navigation_finished():
		return Status.SUCCESS

	if _is_dynamic_target():
		var target_pos : Variant = _resolve_target_pos()
		if target_pos != null:
			_agent.target_position = target_pos

	var next_path_pos : Variant = _agent.get_next_path_position()
	var current_pos : Variant = _node.global_position
	var spd : float = eval(&"speed") as float

	var dir = (next_path_pos - current_pos).normalized()
	if _node is CharacterBody2D:
		_node.velocity = dir * spd
		_node.move_and_slide()
	elif _node is CharacterBody3D:
		_node.velocity = dir * spd
		_node.move_and_slide()
	elif _node is Node2D:
		_node.global_position += dir * spd * delta
	elif _node is Node3D:
		_node.global_position += dir * spd * delta

	return Status.RUNNING

func _is_dynamic_target() -> bool:
	return is_instance_valid(_target_node)

func _resolve_target_pos() -> Variant:
	if is_instance_valid(_target_node) and (_target_node is Node2D or _target_node is Node3D):
		return _target_node.global_position

	var raw_val = eval(&"target")
	if raw_val is Vector2:
		return raw_val if _node is Node2D else Vector3(raw_val.x, raw_val.y, 0)
	if raw_val is Vector3:
		return raw_val if _node is Node3D else Vector2(raw_val.x, raw_val.y)

	return null

func on_end(_status: Status) -> void:
	_node = null
	_agent = null
	_target_node = null

func set_instruction() -> String: return "Navigate {node} to {target}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
