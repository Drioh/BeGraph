@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Jump"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Makes {node} (a CharacterBody2D/3D) jump, giving it an upward vertical speed of {jump_velocity}.\n\nIf {only_on_floor} is true, fails when {node} isn't on the floor.\n\nIf {wait_for_landing} is false, only the vertical velocity is set and the node succeeds immediately: gravity and move_and_slide() are left to the character's own script.\n\nIf {wait_for_landing} is true, this node also applies gravity ({use_project_gravity}, otherwise {custom_gravity}) and calls move_and_slide() every tick, returning RUNNING until the character lands and SUCCESS afterwards. Horizontal velocity is kept as it is.\n\nFails if {node} can't be resolved or isn't a character body."

var _body : Node
var _is_2d : bool = false

func set_instruction() -> String:
	return "Jump {node} (speed {jump_velocity})"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_body):
		_body = _resolve_node(get("node"))
		if _body == null or not (_body is CharacterBody2D or _body is CharacterBody3D):
			push_error("\"%s\" couldn't resolve a character body" % resource_name)
			return Status.FAILURE
		_is_2d = _body is CharacterBody2D

		if get("only_on_floor") and not _body.is_on_floor():
			return Status.FAILURE

		_launch()
		dirty = false
		if not get("wait_for_landing"):
			dirty = true
			tick_next(delta)
			return Status.SUCCESS

	var velocity : Variant = _body.velocity
	var gravity : float = _get_gravity()
	if _is_2d:
		velocity.y += gravity * delta
	else:
		velocity.y -= gravity * delta
	_body.velocity = velocity
	_body.move_and_slide()

	if _body.is_on_floor():
		dirty = true
		tick_next(delta)
		return Status.SUCCESS
	return Status.RUNNING

func _launch() -> void:
	var velocity : Variant = _body.velocity
	var jump_velocity : float = get("jump_velocity")
	velocity.y = -jump_velocity if _is_2d else jump_velocity
	_body.velocity = velocity

func _get_gravity() -> float:
	if get("use_project_gravity"):
		var setting : String = "physics/2d/default_gravity" if _is_2d else "physics/3d/default_gravity"
		return float(ProjectSettings.get_setting(setting))
	return get("custom_gravity")

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CharacterBody2D,CharacterBody3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("jump_velocity", float(400.0))
	_add_behavior_property("only_on_floor", true)
	_add_behavior_property("wait_for_landing", true)
	_add_behavior_property("use_project_gravity", true)
	_add_behavior_property("custom_gravity", float(980.0))
