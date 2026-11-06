@tool
extends Node3D
## Controller for 3D Station 3 (Physics Impulse). physics_impulse_graph.tres hard-codes
## "area"/"node" as raw relative NodePaths ("../PitTriggerArea", "../Crate1", "../Crate2")
## directly on its nodes; those are not absolute and fail at runtime. This script pushes
## TriggerArea / CrateA / CrateB into the blackboard instead.

@onready var actuator: CharacterBody3D = $ActuatorBot
@onready var behavior_agent: BehaviorAgent = $ActuatorBot/BehaviorAgent
@onready var trigger_area: Area3D = $PitTriggerArea
@onready var crate_a: RigidBody3D = $Crate1
@onready var crate_b: RigidBody3D = $Crate2

func _ready() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"TriggerArea", trigger_area.get_path())
	behavior_agent.set_blackboard_property(&"CrateA", crate_a.get_path())
	behavior_agent.set_blackboard_property(&"CrateB", crate_b.get_path())
