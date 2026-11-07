@tool
extends Node2D

@onready var actor: CharacterBody2D = get_node_or_null("TagActor")
@onready var escape_target: Node2D = get_node_or_null("EscapeTarget")
@onready var status_lbl: Label = get_node_or_null("TagActor/StatusLabel")
@onready var nav_region: NavigationRegion2D = get_node_or_null("NavigationRegion2D")
@onready var navigation_agent_2d: NavigationAgent2D = $TagActor/NavigationAgent2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("ArenaZone/CollisionShape2D")
@onready var arena_zone: Area2D = $ArenaZone

var player: Node2D = null

@export var behavior_agent : BehaviorAgent

# 4 corners in the open corridors of the arena
var corners: Array[Vector2] = [
	Vector2(-210, -100),
	Vector2(210, -100),
	Vector2(210, 130),
	Vector2(-210, 130)
]

func _ready() -> void:
	_build_navigation_mesh()
	_find_player()
	_push_blackboard()

func _find_player() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if not player:
		player = get_node_or_null("../../Player")

## Pushes every NodePath the tag_graph.tres blackboard needs. This is the single place that
## knows the real scene structure: the graph resource itself only stores blackboard KEYS
## ("player", "CollisionShape", "EscapeTarget"), never raw relative NodePaths.
func _push_blackboard() -> void:
	if behavior_agent == null or behavior_agent.behavior_graph == null:
		return

	if player:
		behavior_agent.set_blackboard_property(&"player", player.get_path())
	if collision_shape:
		behavior_agent.set_blackboard_property(&"CollisionShape", collision_shape.get_path())
	if escape_target:
		behavior_agent.set_blackboard_property(&"EscapeTarget", escape_target.get_path())
	if arena_zone:
		behavior_agent.set_blackboard_property(&"ArenaZone", arena_zone.get_path())
	if actor:
		behavior_agent.set_blackboard_property(&"TagActor", actor.get_path())
	if navigation_agent_2d:
		behavior_agent.set_blackboard_property(&"NavigationAgent", navigation_agent_2d.get_path())
	if status_lbl:
		behavior_agent.set_blackboard_property(&"StatusLabel", status_lbl.get_path())
		

func _build_navigation_mesh() -> void:
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = 18.0
	nav_poly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_poly.parsed_collision_mask = 2

	# Outer arena boundary
	var outer := PackedVector2Array([
		Vector2(-265, -140),
		Vector2(265, -140),
		Vector2(265, 170),
		Vector2(-265, 170)
	])
	nav_poly.add_outline(outer)

	var source_geometry := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(nav_poly, source_geometry, self)
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)

	if nav_region:
		nav_region.navigation_polygon = nav_poly

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_find_player()

	if escape_target and player:
		# Pick the corner furthest from the player
		var p_pos := player.global_position
		var best_pos := corners[0]
		var max_dist := 0.0
		for c in corners:
			var world_c := to_global(c)
			var d := world_c.distance_squared_to(p_pos)
			if d > max_dist:
				max_dist = d
				best_pos = c
		escape_target.position = best_pos

func reset_tag_game() -> void:
	if actor:
		actor.position = Vector2(0, 80)
		actor.velocity = Vector2.ZERO
		actor.modulate = Color(1.0, 0.25, 0.25, 1.0)
		if status_lbl:
			status_lbl.text = "CHASER"
		if actor.behavior_agent and actor.behavior_agent.behavior_graph:
			_push_blackboard()
			actor.behavior_agent.set_blackboard_property(&"is_fleeing", false)
			actor.behavior_agent.starting_point = 0
			actor.behavior_agent._starting_point_idx = 0
			actor.behavior_agent.notify_property_list_changed()
