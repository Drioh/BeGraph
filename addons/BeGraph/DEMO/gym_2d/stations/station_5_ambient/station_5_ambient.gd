@tool
extends Node2D
## Controller for Station 5 (Ambient): this station never looks outside its own actor, but
## ambient_graph.tres still had "node = NodePath(\".\")" and "node = NodePath(\"StatusLabel\")"
## hard-coded directly on its nodes, which are relative paths and therefore fail at runtime.
## This script pushes "Self" and "StatusLabel" into the blackboard instead.

@onready var behavior_agent: BehaviorAgent = $AmbientActor/BehaviorAgent
@onready var ambient_actor: CharacterBody2D = $AmbientActor
@onready var status_label: Label = $AmbientActor/StatusLabel

func _ready() -> void:
	if behavior_agent == null:
		return

	behavior_agent.set_blackboard_property(&"Self", ambient_actor.get_path())
	behavior_agent.set_blackboard_property(&"StatusLabel", status_label.get_path())
