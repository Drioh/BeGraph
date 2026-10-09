@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Line Of Sight"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"RayCast2D,RayCast3D") var raycast : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY+"Node") var target : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var ray := _resolve_node(eval(&"raycast"))
	var tgt := _resolve_node(eval(&"target"))
	
	if ray == null or tgt == null or not (ray is RayCast2D or ray is RayCast3D):
		return abort("couldn't resolve raycast or target")
		
	ray.enabled = true
	ray.target_position = ray.to_local(tgt.global_position)
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		tick_condition(delta, 1)
		return Status.RUNNING
		
	var collider : Object = ray.get_collider()
	if collider == tgt or (collider is Node and tgt.is_ancestor_of(collider)):
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
