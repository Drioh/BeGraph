@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Get Random Navigation Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes a random point of the navigation map of {node} (Node2D/3D) into the blackboard entry named {variable_name}: a Vector2 for 2D nodes, a Vector3 for 3D ones. Feed it to 'Navigate To'.\n\nIf {radius} is 0 the point is picked anywhere on the map; otherwise it is picked within {radius} units of {node} and snapped to the nearest walkable position.\n\nReturns RUNNING while the navigation map hasn't been synchronized yet (right after the scene starts), then SUCCESS. Fails if {node} can't be resolved or {variable_name} isn't found in the blackboard."

const ALL_LAYERS : int = 0xFFFFFFFF

var _node : Node

func set_instruction() -> String:
	return "Set {variable_name} = random navigation point near {node}"

func tick(delta:float) -> Status:
	if dirty or not is_instance_valid(_node):
		_node = _resolve_node(get("node"))
		if _node == null or not (_node is Node2D or _node is Node3D):
			push_error("\"%s\" couldn't resolve a Node2D/Node3D" % resource_name)
			return Status.FAILURE
		dirty = false

	var graph : BehaviorGraph = _graph_ref.get_ref()
	if graph == null:
		return Status.FAILURE
	var variable : BlackboardVariable = graph.get_blackboard_property(get("variable_name"))
	if variable == null:
		push_error("\"%s\" couldn't find variable \"%s\" in blackboard" % [resource_name, get("variable_name")])
		return Status.FAILURE

	var radius : float = get("radius")
	if _node is Node3D:
		var map : RID = _node.get_world_3d().get_navigation_map()
		if NavigationServer3D.map_get_iteration_id(map) == 0:
			return Status.RUNNING
		if radius <= 0.0:
			variable.value = NavigationServer3D.map_get_random_point(map, ALL_LAYERS, true)
		else:
			var candidate : Vector3 = _node.global_position + _random_direction(true) * sqrt(randf()) * radius
			variable.value = NavigationServer3D.map_get_closest_point(map, candidate)
	else:
		var map : RID = _node.get_world_2d().get_navigation_map()
		if NavigationServer2D.map_get_iteration_id(map) == 0:
			return Status.RUNNING
		if radius <= 0.0:
			variable.value = NavigationServer2D.map_get_random_point(map, ALL_LAYERS, true)
		else:
			var candidate : Vector2 = _node.global_position + Vector2.RIGHT.rotated(randf() * TAU) * sqrt(randf()) * radius
			variable.value = NavigationServer2D.map_get_closest_point(map, candidate)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Node2D,Node3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("variable_name", &"")
	_add_behavior_property("radius", float(0.0))

#region Helpers (self-contained copies, no external dependency)

## Random unit direction: on the XY plane for 2D, on the XZ plane for 3D.
func _random_direction(in_3d: bool) -> Vector3:
	var angle : float = randf() * TAU
	if in_3d:
		return Vector3(cos(angle), 0.0, sin(angle))
	return Vector3(cos(angle), sin(angle), 0.0)

#endregion
