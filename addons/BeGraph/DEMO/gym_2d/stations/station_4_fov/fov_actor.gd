@tool
extends CharacterBody2D

@export var behavior_agent: BehaviorAgent
@export var fov_angle: float = 90.0
@export var fov_distance: float = 260.0
@export var cone_color: Color = Color(1.0, 0.8, 0.2, 0.15)
@export var cone_border_color: Color = Color(1.0, 0.8, 0.2, 0.5)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Draw actor circle
	draw_circle(Vector2.ZERO, 18.0, Color(0.95, 0.8, 0.25, 1.0))
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, Color.WHITE, 2.0, true)

	# Draw eye / forward marker
	draw_line(Vector2.ZERO, Vector2(22.0, 0.0), Color.WHITE, 3.0)

	# Draw FOV cone
	var half_angle := deg_to_rad(fov_angle * 0.5)
	var points: PackedVector2Array = [Vector2.ZERO]
	var num_segments := 24
	for i in range(num_segments + 1):
		var ang := -half_angle + (half_angle * 2.0) * (float(i) / float(num_segments))
		points.append(Vector2(cos(ang), sin(ang)) * fov_distance)

	draw_colored_polygon(points, cone_color)
	draw_polyline(points, cone_border_color, 1.5)
