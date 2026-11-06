@tool
extends Node3D
## Controller for 3D Station 2 (Sentry). Mirrors station_2_sentry.gd (2D): resolves self,
## player, raycast, spotlight, audio player and the projectiles container, then pushes them
## into the blackboard as absolute NodePaths.

@onready var sentry_actor: CharacterBody3D = $SentryActor3D
@onready var behavior_agent: BehaviorAgent = $SentryActor3D/BehaviorAgent
@onready var raycast: RayCast3D = $SentryActor3D/RayCast3D
@onready var spot_light: SpotLight3D = $SentryActor3D/SpotLight3D
@onready var audio_player: AudioStreamPlayer = $SentryActor3D/AudioStreamPlayer
@onready var projectiles_container: Node3D = $Projectiles3D

var player: Node3D = null

func _ready() -> void:
	_find_player()
	_push_blackboard()

func _find_player() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if not player:
		player = get_node_or_null("../Player3D")

func _push_blackboard() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", sentry_actor.get_path())
	behavior_agent.set_blackboard_property(&"RayCast", raycast.get_path())
	behavior_agent.set_blackboard_property(&"SpotLight", spot_light.get_path())
	behavior_agent.set_blackboard_property(&"AudioPlayer", audio_player.get_path())
	behavior_agent.set_blackboard_property(&"ProjectilesParent", projectiles_container.get_path())

	if player:
		behavior_agent.set_blackboard_property(&"Player", player.get_path())
