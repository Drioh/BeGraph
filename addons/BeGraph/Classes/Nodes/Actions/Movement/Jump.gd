@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Jump"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Makes {node} (a CharacterBody2D/3D) jump."

@export_custom(PROPERTY_HINT_NODE_TYPE,BG.PROPERTY+ "CharacterBody2D,CharacterBody3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var jump_velocity : float = 400.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var only_on_floor : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var wait_for_landing : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var use_project_gravity : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var custom_gravity : float = 980.0

var _body : Node
var _is_2d : bool = false

func on_start() -> void:
	_body = _resolve_node(eval(&"node"))
	if _body == null or not (_body is CharacterBody2D or _body is CharacterBody3D):
		abort("couldn't resolve character body")
		return
		
	_is_2d = _body is CharacterBody2D
	if eval(&"only_on_floor") and not _body.is_on_floor():
		abort("character body is not on floor")
		return
		
	var velocity : Variant = _body.velocity
	var j_vel : float = eval(&"jump_velocity") as float
	velocity.y = -j_vel if _is_2d else j_vel
	_body.velocity = velocity

func tick(delta: float) -> Status:
	if not eval(&"wait_for_landing"):
		return tick_next(delta)
		
	var velocity : Variant = _body.velocity
	var gravity : float = _get_gravity()
	if _is_2d:
		velocity.y += gravity * delta
	else:
		velocity.y -= gravity * delta
		
	_body.velocity = velocity
	_body.move_and_slide()
	
	if _body.is_on_floor():
		return tick_next(delta)
		
	return Status.RUNNING

func _get_gravity() -> float:
	if eval(&"use_project_gravity"):
		var setting : String = "physics/2d/default_gravity" if _is_2d else "physics/3d/default_gravity"
		return float(ProjectSettings.get_setting(setting))
	return eval(&"custom_gravity") as float

func set_instruction() -> String: return "Jump {node} (speed {jump_velocity})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
