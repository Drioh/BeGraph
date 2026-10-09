@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Spawn Projectile"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+ "*.tscn,*.scn") var scene_path : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var origin : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var offset : Vector3 = Vector3.ZERO
@export_custom(BG.HINT_NONE, BG.PROPERTY) var direction : Vector3 = Vector3.RIGHT
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 400.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var relative_to_origin : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var lifetime : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""

func tick(delta: float) -> Status:
	var path : String = eval(&"scene_path")
	var scene := load(path) as PackedScene
	if scene == null:
		return abort("couldn't load scene '%s'" % path)
		
	var parent_node := _resolve_node(eval(&"parent"))
	if parent_node == null:
		return abort("couldn't resolve parent node")
		
	var origin_node : Node = null
	if eval(&"origin") != NodePath(""):
		origin_node = _resolve_node(eval(&"origin"))
	if origin_node == null:
		var agent := get_agent()
		if agent != null and "actor" in agent:
			origin_node = agent.actor
			
	if origin_node == null:
		return abort("couldn't resolve origin node")
		
	var instance : Node = scene.instantiate()
	parent_node.add_child(instance)
	
	var off : Vector3 = eval(&"offset") as Vector3
	var dir : Vector3 = eval(&"direction") as Vector3
	var rel : bool = eval(&"relative_to_origin") as bool
	var spd : float = eval(&"speed") as float
	var velocity : Variant = null
	
	if instance is Node2D:
		var origin_tr : Transform2D = origin_node.global_transform if origin_node is Node2D else Transform2D.IDENTITY
		var off_2d := Vector2(off.x, off.y)
		var dir_2d := Vector2(dir.x, dir.y).normalized()
		if rel: dir_2d = origin_tr.basis_xform(dir_2d).normalized()
		instance.global_position = origin_tr * off_2d if rel else origin_tr.origin + off_2d
		instance.rotation = dir_2d.angle()
		velocity = dir_2d * spd
	elif instance is Node3D:
		var origin_tr : Transform3D = origin_node.global_transform if origin_node is Node3D else Transform3D.IDENTITY
		var dir_3d : Vector3 = dir.normalized()
		if rel: dir_3d = (origin_tr.basis * dir_3d).normalized()
		instance.global_position = origin_tr * off if rel else origin_tr.origin + off
		if dir_3d != Vector3.ZERO:
			var up : Vector3 = Vector3.UP if absf(dir_3d.dot(Vector3.UP)) < 0.999 else Vector3.RIGHT
			instance.look_at(instance.global_position + dir_3d, up)
		velocity = dir_3d * spd
		
	if velocity != null:
		if "linear_velocity" in instance: instance.set("linear_velocity", velocity)
		elif "velocity" in instance: instance.set("velocity", velocity)
		
	var life : float = eval(&"lifetime") as float
	if life > 0.0:
		instance.get_tree().create_timer(life).timeout.connect(instance.queue_free)
		
	var var_name : StringName = eval(&"variable_name") as StringName
	if var_name != &"":
		var graph := get_graph()
		if graph != null:
			var variable := graph.get_blackboard_property(var_name)
			if variable != null: variable.value = instance
			
	return tick_next(delta)

func set_instruction() -> String: return "Spawn {scene_path} under {parent} from {origin}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
