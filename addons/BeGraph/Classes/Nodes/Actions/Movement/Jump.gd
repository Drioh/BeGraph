@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Jump"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Applies vertical velocity to {node} (CharacterBody2D/3D) using {jump_height} and gravity.\n\nReturns RUNNING while in the air and SUCCESS upon landing; fails if {node} is not grounded."

@export_custom(BG.HINT_NONE, BG.PROPERTY+"CharacterBody2D,CharacterBody3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var jump_height : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var wait_for_landing : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var custom_gravity : float = -1.0

var _body_ref : Node
var _left_floor : bool = false

func on_start() -> void:
	_body_ref = eval(&"node", true)
	_left_floor = false
	
	if not (_body_ref is CharacterBody2D or _body_ref is CharacterBody3D):
		abort("couldn't resolve character body")
		return
		
	if not _body_ref.is_on_floor():
		abort("character body is not on floor")
		return
		
	var h : float = eval(&"jump_height") as float
	var g : float = _resolve_gravity(_body_ref is CharacterBody3D)
	var vy : float = sqrt(2.0 * g * h)
	
	if _body_ref is CharacterBody2D:
		_body_ref.velocity.y = -vy
	else:
		_body_ref.velocity.y = vy
		
	_body_ref.move_and_slide()

func tick(_delta: float) -> Status:
	if _body_ref == null or not is_instance_valid(_body_ref):
		return Status.FAILURE
		
	if not eval(&"wait_for_landing"):
		return Status.SUCCESS
		
	if not _left_floor:
		if not _body_ref.is_on_floor():
			_left_floor = true
		return Status.RUNNING
		
	if _body_ref.is_on_floor():
		return Status.SUCCESS
		
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_body_ref = null

func _resolve_gravity(in_3d: bool) -> float:
	var custom_g : float = eval(&"custom_gravity") as float
	if custom_g > 0.0:
		return custom_g
	var setting : String = "physics/3d/default_gravity" if in_3d else "physics/2d/default_gravity"
	return float(ProjectSettings.get_setting(setting))

func set_instruction() -> String: return "Jump {node} (height: {jump_height})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
