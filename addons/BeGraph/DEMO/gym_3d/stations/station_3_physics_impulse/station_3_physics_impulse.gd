@tool
extends Node3D
## Controller for 3D Station 3 (Physics Impulse). Pushes TriggerArea / CrateA / CrateB
## into the blackboard and keeps the physics objects contained inside their pit arena.

@onready var actuator: CharacterBody3D = $ActuatorBot
@onready var behavior_agent: BehaviorAgent = $ActuatorBot/BehaviorAgent
@onready var trigger_area: Area3D = $PitTriggerArea
@onready var crate_a: RigidBody3D = $Crate1
@onready var crate_b: RigidBody3D = $Crate2

func _ready() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", actuator.get_path())
	behavior_agent.set_blackboard_property(&"TriggerArea", trigger_area.get_path())
	behavior_agent.set_blackboard_property(&"CrateA", crate_a.get_path())
	behavior_agent.set_blackboard_property(&"CrateB", crate_b.get_path())

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_keep_in_pit(crate_a, Vector3(-2.2, 0.8, -1.8))
	_keep_in_pit(crate_b, Vector3(2.2, 0.8, 1.8))

func _keep_in_pit(body: RigidBody3D, home_pos: Vector3) -> void:
	if body == null:
		return
	if body.position.y < -0.5 or absf(body.position.x) > 5.0 or absf(body.position.z) > 5.0:
		body.position = Vector3(
			clampf(body.position.x, -4.5, 4.5),
			maxf(body.position.y, 0.8),
			clampf(body.position.z, -4.5, 4.5)
		)
		if body.position.y < 0.0:
			body.position = home_pos
		body.linear_velocity.x = 0.0
		body.linear_velocity.z = 0.0
