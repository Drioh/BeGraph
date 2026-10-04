@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Spawn Projectile"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Instantiates the scene {scene_path} under {parent}, places it at {offset} relative to {origin} (empty = the agent's actor), points it along {direction} and gives it {speed} units/second.\n\nIf {relative_to_origin} is true, {offset} and {direction} are rotated with {origin} (so (1, 0, 0) means 'forward' for a 2D node facing right); otherwise they are global.\n\nThe speed is applied to the instance's linear_velocity (RigidBody) or velocity (CharacterBody or any script exposing that property); other scenes are only placed and rotated.\n\nIf {lifetime} is greater than 0 the instance is freed after that many seconds. If {variable_name} isn't empty, the instance is also written into that blackboard entry.\n\nSucceeds once spawned; fails if the scene can't be loaded or {parent}/{origin} can't be resolved."

func set_instruction() -> String:
	return "Spawn {scene_path} under {parent} from {origin}"

func tick(delta:float) -> Status:
	var scene : PackedScene = load(get("scene_path")) as PackedScene
	if scene == null:
		push_error("\"%s\" couldn't load scene \"%s\"" % [resource_name, get("scene_path")])
		return Status.FAILURE

	var parent : Node = _resolve_node(get("parent"))
	if parent == null:
		push_error("\"%s\" couldn't resolve parent node" % resource_name)
		return Status.FAILURE

	var origin : Node = null
	if get("origin") != NodePath(""):
		origin = _resolve_node(get("origin"))
	if origin == null:
		var agent : Node = get_agent()
		origin = agent.actor if agent != null else null
	if origin == null:
		push_error("\"%s\" couldn't resolve origin node" % resource_name)
		return Status.FAILURE

	var instance : Node = scene.instantiate()
	parent.add_child(instance)

	var offset : Vector3 = get("offset")
	var direction : Vector3 = get("direction")
	var relative : bool = get("relative_to_origin")
	var velocity : Variant = null

	if instance is Node2D:
		var origin_transform : Transform2D = origin.global_transform if origin is Node2D else Transform2D.IDENTITY
		var offset_2d : Vector2 = Vector2(offset.x, offset.y)
		var direction_2d : Vector2 = Vector2(direction.x, direction.y).normalized()
		if relative:
			direction_2d = origin_transform.basis_xform(direction_2d).normalized()
			instance.global_position = origin_transform * offset_2d
		else:
			instance.global_position = origin_transform.origin + offset_2d
		instance.rotation = direction_2d.angle()
		velocity = direction_2d * float(get("speed"))
	elif instance is Node3D:
		var origin_transform : Transform3D = origin.global_transform if origin is Node3D else Transform3D.IDENTITY
		var direction_3d : Vector3 = direction.normalized()
		if relative:
			direction_3d = (origin_transform.basis * direction_3d).normalized()
			instance.global_position = origin_transform * offset
		else:
			instance.global_position = origin_transform.origin + offset
		if direction_3d != Vector3.ZERO:
			var up : Vector3 = Vector3.UP if absf(direction_3d.dot(Vector3.UP)) < 0.999 else Vector3.RIGHT
			instance.look_at(instance.global_position + direction_3d, up)
		velocity = direction_3d * float(get("speed"))

	if velocity != null:
		if "linear_velocity" in instance:
			instance.set("linear_velocity", velocity)
		elif "velocity" in instance:
			instance.set("velocity", velocity)

	var lifetime : float = get("lifetime")
	if lifetime > 0.0:
		instance.get_tree().create_timer(lifetime).timeout.connect(instance.queue_free)

	var variable_name : StringName = get("variable_name")
	if variable_name != &"":
		var graph : BehaviorGraph = _graph_ref.get_ref()
		var variable : BlackboardVariable = graph.get_blackboard_property(variable_name) if graph != null else null
		if variable != null:
			variable.value = instance

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("scene_path", "", PROPERTY_HINT_FILE, "*.tscn,*.scn")
	_add_behavior_property("parent", NodePath(""))
	_add_behavior_property("origin", NodePath(""))
	_add_behavior_property("offset", Vector3.ZERO)
	_add_behavior_property("direction", Vector3.RIGHT)
	_add_behavior_property("speed", float(400.0))
	_add_behavior_property("relative_to_origin", true)
	_add_behavior_property("lifetime", float(0.0))
	_add_behavior_property("variable_name", &"")
