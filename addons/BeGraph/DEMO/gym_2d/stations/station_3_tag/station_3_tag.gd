@tool
extends Node2D

@onready var actor: CharacterBody2D = get_node_or_null("TagActor")
@onready var escape_target: Node2D = get_node_or_null("EscapeTarget")
@onready var status_lbl: Label = get_node_or_null("TagActor/StatusLabel")
@onready var nav_region: NavigationRegion2D = get_node_or_null("NavigationRegion2D")

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
	
	if behavior_agent:
		behavior_agent.set_blackboard_property(&"player",player.get_path())

func _find_player() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if not player:
		player = get_node_or_null("../../Player")

func _build_navigation_mesh() -> void:
	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = 18.0

	# 1. Outer arena boundary
	var outer := PackedVector2Array([
		Vector2(-260, -135),
		Vector2(260, -135),
		Vector2(260, 165),
		Vector2(-260, 165)
	])
	nav_poly.add_outline(outer)

	# 2. Obstacle holes with agent radius padding (18px)
	var obstacles: Array[Dictionary] = [
		{"pos": Vector2(-120, -40), "size": Vector2(48, 72)},
		{"pos": Vector2(120, -40), "size": Vector2(48, 72)},
		{"pos": Vector2(-120, 70), "size": Vector2(48, 72)},
		{"pos": Vector2(120, 70), "size": Vector2(48, 72)},
		{"pos": Vector2(0, 15), "size": Vector2(64, 32)}
	]

	for obs in obstacles:
		var p: Vector2 = obs["pos"]
		var s: Vector2 = obs["size"]
		var hw: float = s.x * 0.5 + 18.0
		var hh: float = s.y * 0.5 + 18.0
		var hole := PackedVector2Array([
			Vector2(p.x - hw, p.y - hh),
			Vector2(p.x + hw, p.y - hh),
			Vector2(p.x + hw, p.y + hh),
			Vector2(p.x - hw, p.y + hh)
		])
		nav_poly.add_outline(hole)

	nav_poly.make_polygons_from_outlines()

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
			actor.behavior_agent.set_blackboard_property(&"is_fleeing", false)
			actor.behavior_agent.set_blackboard_property(&"player", player)
			actor.behavior_agent.starting_point = 0
			actor.behavior_agent._starting_point_idx = 0
			actor.behavior_agent.notify_property_list_changed()
