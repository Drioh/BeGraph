@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Spawn Projectile"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Spawns a projectile scene towards a target (Node/NodePath/Vector) or along a direction vector. Updates dynamically if the target is a Blackboard variable."

@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+"*.tscn,*.scn") var scene_path : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var origin : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var offset : Vector3 = Vector3.ZERO
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var direction : Vector3 = Vector3.RIGHT
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 400.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var relative_to_origin : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var lifetime : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""

var _cached_target_node : Node = null
var _cached_target_pos : Variant = null

func on_start() -> void:
	_update_target_cache()

func on_blackboard_property_changed(key: StringName) -> void:
	var current_target_key = eval(&"target")
	if (current_target_key is StringName or current_target_key is String) and StringName(current_target_key) == key:
		_update_target_cache()

func tick(_delta: float) -> Status:
	var path : String = eval(&"scene_path")
	var scene := load(path) as PackedScene
	if scene == null:
		return abort("couldn't load scene '%s'" % path)
		
	var parent_node := eval(&"parent", true)
	if parent_node == null:
		return abort("couldn't resolve parent node")
		
	var origin_node : Node = eval(&"origin", true)
	if origin_node == null:
		var agent := get_agent()
		if agent != null and "actor" in agent:
			origin_node = agent.actor
			
	if origin_node == null:
		return abort("couldn't resolve origin node")

	var instance : Node = scene.instantiate()
	parent_node.add_child(instance)

	var off : Vector3 = eval(&"offset") as Vector3
	var spd : float = eval(&"speed") as float
	var rel : bool = eval(&"relative_to_origin") as bool
	
	# Origin position resolution
	var origin_pos_3d : Vector3 = Vector3.ZERO
	if origin_node is Node2D:
		origin_pos_3d = Vector3(origin_node.global_position.x, origin_node.global_position.y, 0.0)
	elif origin_node is Node3D:
		origin_pos_3d = origin_node.global_position

	var spawn_pos_3d : Vector3 = origin_pos_3d + off

	# Direction computation
	var final_dir_3d : Vector3 = Vector3.ZERO
	var target_pos : Variant = _get_target_position()

	if target_pos != null:
		final_dir_3d = ((target_pos as Vector3) - spawn_pos_3d).normalized()
	else:
		var dir_val : Vector3 = eval(&"direction") as Vector3
		final_dir_3d = dir_val.normalized()
		if rel:
			if origin_node is Node2D:
				var dir_2d := Vector2(final_dir_3d.x, final_dir_3d.y).normalized()
				dir_2d = origin_node.global_transform.basis_xform(dir_2d).normalized()
				final_dir_3d = Vector3(dir_2d.x, dir_2d.y, 0.0)
			elif origin_node is Node3D:
				final_dir_3d = (origin_node.global_transform.basis * final_dir_3d).normalized()

	var velocity : Variant = null

	if instance is Node2D:
		var spawn_pos_2d := Vector2(spawn_pos_3d.x, spawn_pos_3d.y)
		var dir_2d := Vector2(final_dir_3d.x, final_dir_3d.y).normalized()
		if dir_2d == Vector2.ZERO: dir_2d = Vector2.RIGHT

		instance.global_position = spawn_pos_2d
		instance.rotation = dir_2d.angle()
		velocity = dir_2d * spd
	elif instance is Node3D:
		if final_dir_3d == Vector3.ZERO: final_dir_3d = Vector3.FORWARD

		instance.global_position = spawn_pos_3d
		var up : Vector3 = Vector3.UP if absf(final_dir_3d.dot(Vector3.UP)) < 0.999 else Vector3.RIGHT
		instance.look_at(spawn_pos_3d + final_dir_3d, up)
		velocity = final_dir_3d * spd

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
			graph.set_blackboard_value(var_name, instance)

	return Status.SUCCESS

func on_end(_status: Status) -> void:
	_cached_target_node = null
	_cached_target_pos = null

func _update_target_cache() -> void:
	_cached_target_node = null
	_cached_target_pos = null
	var value : Variant = eval(&"target")
	if value == null:
		return
	if value is Vector3:
		_cached_target_pos = value
	elif value is Vector2:
		_cached_target_pos = Vector3(value.x, value.y, 0.0)
	else:
		_cached_target_node = _resolve_node(value)

func _get_target_position() -> Variant:
	if _cached_target_node != null and is_instance_valid(_cached_target_node):
		if _cached_target_node is Node2D:
			return Vector3(_cached_target_node.global_position.x, _cached_target_node.global_position.y, 0.0)
		if _cached_target_node is Node3D:
			return _cached_target_node.global_position
	return _cached_target_pos

func set_instruction() -> String: return "Spawn {scene_path} from {origin} (target: {target})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
