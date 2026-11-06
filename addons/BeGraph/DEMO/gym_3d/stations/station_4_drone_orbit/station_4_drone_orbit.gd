@tool
extends Node3D
## Controller for 3D Station 4 (Drone Orbit). Pushes Self / Player / CenterPylon / ArenaZone
## into the blackboard, clamps the drone within its platform bounds on the same idle frame
## (after BehaviorAgent ticks) so there is zero vertical jitter, and prevents pillar penetration.

@onready var drone_actor: CharacterBody3D = $DroneActor
@onready var behavior_agent: BehaviorAgent = $DroneActor/BehaviorAgent
@onready var center_pylon: StaticBody3D = $CenterPylon
@onready var arena_zone: Area3D = $ArenaZone

var player: Node3D = null

func _ready() -> void:
	process_priority = 10
	_find_player()
	_push_blackboard()

func _find_player() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if not player:
		player = get_node_or_null("../../Player3D")
	if not player:
		player = get_node_or_null("../Player3D")

func _push_blackboard() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", drone_actor.get_path())
	behavior_agent.set_blackboard_property(&"CenterPylon", center_pylon.get_path())
	if arena_zone:
		behavior_agent.set_blackboard_property(&"ArenaZone", arena_zone.get_path())

	if player:
		behavior_agent.set_blackboard_property(&"Player", player.get_path())

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or drone_actor == null:
		return
	# Keep constant hover altitude on the exact frame Keep Distance / Orbit updates global_position
	drone_actor.position.y = 1.5
	drone_actor.position.x = clampf(drone_actor.position.x, -5.5, 5.5)
	drone_actor.position.z = clampf(drone_actor.position.z, -5.5, 5.5)

	# Prevent penetrating the CenterPylon (pylon radius 0.5 + drone radius 0.4 = 0.9m)
	var pylon_pos := Vector2(center_pylon.position.x, center_pylon.position.z) if center_pylon else Vector2.ZERO
	var drone_xz := Vector2(drone_actor.position.x, drone_actor.position.z)
	var diff := drone_xz - pylon_pos
	var min_dist := 0.95
	if diff.length() < min_dist:
		var push_dir := diff.normalized() if diff.length() > 0.001 else Vector2.RIGHT
		var pushed := pylon_pos + push_dir * min_dist
		drone_actor.position.x = pushed.x
		drone_actor.position.z = pushed.y
