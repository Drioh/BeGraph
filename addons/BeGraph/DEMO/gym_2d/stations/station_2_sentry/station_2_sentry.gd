@tool
extends Node2D
## Controller for Station 2 (Sentry): resolves every Node reference the behavior graph needs
## (self, player, raycast, audio player, projectiles container) at runtime and pushes them
## into the BehaviorAgent's blackboard as absolute NodePaths, exactly like station_1_patrol.gd
## does for its actors. The graph itself only knows blackboard KEYS ("Self", "Player",
## "RayCast", "AudioPlayer", "ProjectilesParent"); this script is the only place that knows
## the concrete scene structure.

@onready var sentry_actor: CharacterBody2D = $SentryActor
@onready var behavior_agent: BehaviorAgent = $SentryActor/BehaviorAgent
@onready var raycast: RayCast2D = $SentryActor/RayCast2D
@onready var audio_player: AudioStreamPlayer = $SentryActor/AudioStreamPlayer
@onready var projectiles_container: Node2D = $ProjectilesContainer

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
	#behavior_agent.set_blackboard_property(&"Self", sentry_actor.get_path())
	behavior_agent.set_blackboard_property(&"Player", player.get_path())
	#behavior_agent.set_blackboard_property(&"RayCast", raycast.get_path())
	#behavior_agent.set_blackboard_property(&"AudioPlayer", audio_player.get_path())
	#behavior_agent.set_blackboard_property(&"ProjectilesParent", projectiles_container.get_path())
