@tool
extends Sprite2D

@export var behavior_agent : BehaviorAgent

func _get_property_list() -> Array[Dictionary]:
	if behavior_agent:
		return behavior_agent.get_overridable_property_list()
	return []

func _get(property: StringName) -> Variant:
	if behavior_agent and behavior_agent.is_overridable_blackboard_property(property):
		return behavior_agent.get_overridable_blackboard_property(property)
	return 

func _set(property: StringName, value: Variant) -> bool:
	if behavior_agent and behavior_agent.is_overridable_blackboard_property(property):
		return behavior_agent.set_overridable_blackboard_property(property,value,self)
	return false
