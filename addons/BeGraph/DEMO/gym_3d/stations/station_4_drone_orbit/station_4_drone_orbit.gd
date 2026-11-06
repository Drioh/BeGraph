@tool
extends Node3D
## Controller for 3D Station 4 (Drone Orbit). Pushes Self / Player / CenterPylon into the
## blackboard so drone_orbit_graph.tres's nodes stop relying on raw relative NodePaths
## like "../../../Player3D" or "../CenterPylon".

@onready var drone_actor: CharacterBody3D = $DroneActor
@onready var behavior_agent: BehaviorAgent = $DroneActor/BehaviorAgent
@onready var center_pylon: StaticBody3D = $CenterPylon

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

	behavior_agent.set_blackboard_property(&"Self", drone_actor.get_path())
	behavior_agent.set_blackboard_property(&"CenterPylon", center_pylon.get_path())

	if player:
		behavior_agent.set_blackboard_property(&"Player", player.get_path())
