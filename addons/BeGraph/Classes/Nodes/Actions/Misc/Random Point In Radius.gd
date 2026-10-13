@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Point In Radius"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Generates a random point within a radius around target node or origin and stores it in a blackboard variable."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 200.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var key : StringName = eval(&"blackboard_key")
	if key == &"":
		return abort("no blackboard key set")
		
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var center_node := eval(&"node", true)
	var in_3d : bool = center_node is Node3D
	var center : Vector3 = Vector3.ZERO
	if center_node is Node2D:
		center = Vector3(center_node.global_position.x, center_node.global_position.y, 0.0)
	elif center_node is Node3D:
		center = center_node.global_position
		
	var angle : float = randf() * TAU
	var r : float = sqrt(randf()) * (eval(&"radius") as float)
	var offset : Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * r if in_3d else Vector3(cos(angle), sin(angle), 0.0) * r
	var point : Vector3 = center + offset
	
	if in_3d:
		graph.set_blackboard_value(key, point)
	else:
		graph.set_blackboard_value(key, Vector2(point.x, point.y))
		
	return Status.SUCCESS

func set_instruction() -> String: return "Random point around {node} within {radius} into {blackboard_key}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
