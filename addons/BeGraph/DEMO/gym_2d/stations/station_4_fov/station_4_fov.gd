@tool
extends Node2D
## Controller for Station 4 (FOV): resolves "self", the player and the status label at
## runtime and pushes them into the BehaviorAgent's blackboard, instead of relying on the
## raw relative NodePaths ("../../../Player", "StatusLabel", ".") that fov_graph.tres had
## hard-coded on its nodes - those fail at runtime because BehaviorNode._resolve_node()
## only accepts absolute NodePaths.

@onready var fov_actor: CharacterBody2D = $FOVActor
@onready var behavior_agent: BehaviorAgent = $FOVActor/BehaviorAgent
@onready var status_label: Label = $FOVActor/StatusLabel

var player: Node2D = null

func _ready() -> void:
	_find_player()
	_push_blackboard()

func _find_player() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if not player:
		player = get_node_or_null("../Player")

func _push_blackboard() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", fov_actor.get_path())
	behavior_agent.set_blackboard_property(&"StatusLabel", status_label.get_path())

	if player:
		behavior_agent.set_blackboard_property(&"Player", player.get_path())
