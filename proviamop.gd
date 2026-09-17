extends Sprite2D

@onready var behavior_agent: BehaviorAgent = $BehaviorAgent

@export var patrol_points: Array[NodePath] = []

func _ready() -> void:
	if patrol_points.is_empty():
		return
	var points : Array[Node2D] = []
	for p in patrol_points:
		points.append(get_node(p))
	behavior_agent.behavior_graph.get_blackboard_property(&"Positions").value = points
