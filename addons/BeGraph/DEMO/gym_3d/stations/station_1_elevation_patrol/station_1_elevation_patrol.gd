@tool
extends Node3D
## Controller for 3D Station 1 (Elevation Patrol). patrol_elevation.tres never actually sets
## a "waypoints" container on its Patrol node (it was left at the default empty NodePath),
## so Patrol.on_start() currently aborts with "couldn't resolve waypoints container". This
## script wires up Self / Waypoints / ParticleEmitter via the blackboard, the same way
## station_1_patrol.gd does for the 2D patrol actors.
##
## Scene requirement: group Waypoint1/Waypoint2/Waypoint3 under a single "Waypoints"
## Node3D container (sibling of ClimberActor), since Patrol.gd walks a container's
## children in sibling order - see GUIDE.md for the exact .tscn change.

@onready var climber_actor: CharacterBody3D = $ClimberActor
@onready var behavior_agent: BehaviorAgent = $ClimberActor/BehaviorAgent
@onready var waypoints: Node3D = $Waypoints
@onready var particles: CPUParticles3D = $ClimberActor/CPUParticles3D

func _ready() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", climber_actor.get_path())
	behavior_agent.set_blackboard_property(&"ParticleEmitter", particles.get_path())

	if waypoints:
		behavior_agent.set_blackboard_property(&"Waypoints", waypoints.get_path())
	else:
		push_warning("Station1_ElevationPatrol: no 'Waypoints' container found - see GUIDE.md")
