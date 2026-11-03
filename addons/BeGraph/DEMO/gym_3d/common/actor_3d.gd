@tool
extends CharacterBody3D
class_name Actor3D

@export var behavior_agent: BehaviorAgent

@export var actor_color: Color = Color.WHITE:
	set(v):
		actor_color = v
		_apply_color(v)

var _mat_instance: StandardMaterial3D = null

func _get_property_list() -> Array[Dictionary]:
	if behavior_agent:
		return behavior_agent.get_overridable_property_list()
	return []

func _get(property: StringName) -> Variant:
	if property == "actor_color":
		return actor_color
	if behavior_agent and behavior_agent.is_overridable_blackboard_property(property):
		return behavior_agent.get_overridable_blackboard_property(property)
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == "actor_color":
		actor_color = value
		return true
	if behavior_agent and behavior_agent.is_overridable_blackboard_property(property):
		return behavior_agent.set_overridable_blackboard_property(property, value, self)
	return false

func _ready() -> void:
	if behavior_agent:
		behavior_agent.actor = self
	_apply_color(actor_color)
	if not Engine.is_editor_hint():
		# Settle on floor immediately so is_on_floor() is true before BehaviorAgent ticks
		move_and_slide()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_on_floor():
		var g := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
		velocity.y -= g * delta
	move_and_slide()

func _apply_color(col: Color) -> void:
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst == null:
		return
	if _mat_instance == null:
		if mesh_inst.material_override is StandardMaterial3D:
			_mat_instance = mesh_inst.material_override.duplicate() as StandardMaterial3D
		elif mesh_inst.mesh and mesh_inst.mesh.material is StandardMaterial3D:
			_mat_instance = mesh_inst.mesh.material.duplicate() as StandardMaterial3D
		else:
			_mat_instance = StandardMaterial3D.new()
		mesh_inst.material_override = _mat_instance
	_mat_instance.albedo_color = col
