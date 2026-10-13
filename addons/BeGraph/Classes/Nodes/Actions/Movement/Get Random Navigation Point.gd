@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Get Random Nav Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Finds a random reachable navigation point on a NavigationServer within a given radius and stores it in a blackboard variable."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 300.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not (target is Node2D or target is Node3D):
		return abort("couldn't resolve Node2D/Node3D")
		
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var key : StringName = eval(&"blackboard_key")
	if key == &"" or graph.get_blackboard_property(key) == null:
		return abort("blackboard variable '%s' not found" % key)
		
	var in_3d : bool = target is Node3D
	var center : Vector3 = target.global_position if in_3d else Vector3(target.global_position.x, target.global_position.y, 0.0)
	var rad : float = eval(&"radius") as float
	var random_point : Vector3 = center + _random_dir(in_3d) * randf() * rad
	
	if in_3d:
		var map_3d :RID= target.get_world_3d().navigation_map
		var point_3d := NavigationServer3D.map_get_closest_point(map_3d, random_point)
		graph.set_blackboard_value(key, point_3d)
	else:
		var map_2d :RID= target.get_world_2d().navigation_map
		var candidate := Vector2(random_point.x, random_point.y)
		var point_2d := NavigationServer2D.map_get_closest_point(map_2d, candidate)
		graph.set_blackboard_value(key, point_2d)
		
	return Status.SUCCESS

func _random_dir(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle)) if in_3d else Vector3(cos(angle), sin(angle), 0.0)

func set_instruction() -> String: return "Store random nav point around {node} in {blackboard_key}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
