@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Get Random Navigation Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

const ALL_LAYERS : int = 0xFFFFFFFF

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 0.0

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not (target is Node2D or target is Node3D):
		return abort("couldn't resolve Node2D/Node3D")
		
	var key : StringName = eval(&"variable_name") as StringName
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var variable := graph.get_blackboard_property(key)
	if variable == null:
		return abort("blackboard variable '%s' not found" % key)
		
	var rad : float = eval(&"radius") as float
	if target is Node3D:
		var map : RID = target.get_world_3d().get_navigation_map()
		if NavigationServer3D.map_get_iteration_id(map) == 0:
			return Status.RUNNING
		if rad <= 0.0:
			variable.value = NavigationServer3D.map_get_random_point(map, ALL_LAYERS, true)
		else:
			var candidate : Vector3 = target.global_position + _random_dir(true) * sqrt(randf()) * rad
			variable.value = NavigationServer3D.map_get_closest_point(map, candidate)
	else:
		var map : RID = target.get_world_2d().get_navigation_map()
		if NavigationServer2D.map_get_iteration_id(map) == 0:
			return Status.RUNNING
		if rad <= 0.0:
			variable.value = NavigationServer2D.map_get_random_point(map, ALL_LAYERS, true)
		else:
			var candidate : Vector2 = target.global_position + Vector2.RIGHT.rotated(randf() * TAU) * sqrt(randf()) * rad
			variable.value = NavigationServer2D.map_get_closest_point(map, candidate)
			
	return tick_next(delta)

func _random_dir(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle)) if in_3d else Vector3(cos(angle), sin(angle), 0.0)

func set_instruction() -> String: return "Set {variable_name} = random navigation point near {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
