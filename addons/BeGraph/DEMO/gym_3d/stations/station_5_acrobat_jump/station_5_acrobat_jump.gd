@tool
extends Node3D
## Controller for 3D Station 5 (Acrobat Jump). Pushes Self / MeshInstance into the blackboard
## so acrobat_jump_graph.tres's nodes stop relying on raw relative NodePaths ("." and
## "MeshInstance3D") hard-coded directly on the Jump / Tween Property / Rotate Node actions.

@onready var acrobat_bot: CharacterBody3D = $AcrobatBot
@onready var behavior_agent: BehaviorAgent = $AcrobatBot/BehaviorAgent
@onready var mesh_instance: MeshInstance3D = $AcrobatBot/MeshInstance3D

func _ready() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", acrobat_bot.get_path())
	behavior_agent.set_blackboard_property(&"MeshInstance", mesh_instance.get_path())
