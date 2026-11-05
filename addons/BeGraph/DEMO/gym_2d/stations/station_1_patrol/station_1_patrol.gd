@tool
extends Node2D

@onready var waypoint_a1: Node2D = $WaypointsA/WaypointA1
@onready var waypoint_b1: Node2D = $WaypointsB/WaypointB1
@onready var waypoint_c1: Node2D = $WaypointsC/WaypointC1
@onready var waypoint_d1: Node2D = $WaypointsD/WaypointD1
@onready var actor_a: Node2D = $ActorA
@onready var actor_b: Node2D = $ActorB
@onready var actor_c: Node2D = $ActorC
@onready var actor_d: Node2D = $ActorD
@onready var label_a: Label = $ActorA/StatusLabel
@onready var label_b: Label = $ActorB/StatusLabel
@onready var label_c: Label = $ActorC/StatusLabel
@onready var label_d: Label = $ActorD/StatusLabel
@onready var reset_button_node: Button = $ResetButtonNode/Control/Button

func _ready() -> void:
	reset_actors()

	actor_a.behavior_agent.set_blackboard_property(&"waypoints",$WaypointsA.get_path())
	actor_b.behavior_agent.set_blackboard_property(&"waypoints",$WaypointsB.get_path())
	actor_c.behavior_agent.set_blackboard_property(&"waypoints",$WaypointsC.get_path())
	actor_d.behavior_agent.set_blackboard_property(&"waypoints",$WaypointsD.get_path())
	
func _draw() -> void:
	reset_button_node.pressed.connect(reset_actors)
	
	# Draw circuit paths for each patrol variant
	_draw_path(["WaypointA1", "WaypointA2", "WaypointA3"], Color(0.2, 0.8, 0.4, 0.4))
	_draw_path(["WaypointB1", "WaypointB2", "WaypointB3"], Color(0.9, 0.6, 0.2, 0.4))
	_draw_path(["WaypointC1", "WaypointC2", "WaypointC3", "WaypointC4"], Color(0.3, 0.7, 0.9, 0.4))
	_draw_path(["WaypointD1", "WaypointD2", "WaypointD3", "WaypointD4"], Color(0.922, 0.0, 0.11, 0.4))

func _draw_path(point_names: Array, color: Color) -> void:
	var pts: Array[Vector2] = []
	for p_name in point_names:
		var n: Node2D = get_node_or_null(p_name)
		if n:
			pts.append(n.position)
			draw_circle(n.position, 4.0, color.lerp(Color.WHITE, 0.5))

	if pts.size() > 1:
		for i in range(pts.size() - 1):
			draw_dashed_line(pts[i], pts[i+1], color, 2.0, 5.0)

func reset_actors() -> void:
	if actor_a and waypoint_a1:
		actor_a.global_position = waypoint_a1.global_position
		actor_a.modulate = Color.WHITE
		actor_a.set(&"moving",true)
		if label_a:
			label_a.text = "Patrol: Once"
		
	if actor_b and waypoint_b1:
		actor_b.global_position = waypoint_b1.global_position
		actor_b.modulate = Color.WHITE
		actor_b.set(&"moving",true)
		if label_b:
			label_b.text = "Patrol: Ping-Pong"
	
	if actor_c and waypoint_c1:
		actor_c.global_position = waypoint_c1.global_position
		actor_c.modulate = Color.WHITE
		actor_c.set(&"moving",true)
		if label_c:
			label_c.text = "Patrol: Loop"
	
	if actor_d and waypoint_d1:
		actor_d.global_position = waypoint_d1.global_position
		actor_d.modulate = Color.WHITE
		actor_d.set(&"moving",true)
		if label_d:
			label_d.text = "Patrol: Ping-Pong (Loop)"
