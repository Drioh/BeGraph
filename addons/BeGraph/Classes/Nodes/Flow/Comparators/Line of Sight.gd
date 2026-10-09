@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Line Of Sight"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"RayCast2D,RayCast3D") var raycast : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY+"Node") var target : NodePath = NodePath("")

var _ray : Node = null
var _target_ref : Node = null

func on_start() -> void:
	_ray = _resolve_node(eval(&"raycast"))
	_target_ref = _resolve_node(eval(&"target"))

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"raycast"):
		_ray = _resolve_node(eval(&"raycast"))
	if key == get_blackboard_key(&"target"):
		_target_ref = _resolve_node(eval(&"target"))

func tick(delta: float) -> Status:
	if _ray == null or _target_ref == null or not is_instance_valid(_ray) or not is_instance_valid(_target_ref) or not (_ray is RayCast2D or _ray is RayCast3D):
		return abort("couldn't resolve raycast or target")
		
	_ray.enabled = true
	_ray.target_position = _ray.to_local(_target_ref.global_position)
	_ray.force_raycast_update()
	
	if not _ray.is_colliding():
		tick_condition(delta, 1)
		return Status.RUNNING
		
	var collider : Object = _ray.get_collider()
	if collider == _target_ref or (collider is Node and _target_ref.is_ancestor_of(collider)):
		tick_condition(delta, 0)
	else:
		tick_condition(delta, 1)
		
	return Status.RUNNING

func set_instruction() -> String: return "Line of sight from {raycast} to {target}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Target visible", "Target obstructed / out of range"])
