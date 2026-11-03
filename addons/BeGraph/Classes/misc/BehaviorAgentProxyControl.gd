@tool
extends Control
class_name BehaviorAgentProxyControl

@export var behavior_agent: BehaviorAgent

func _get_property_list() -> Array[Dictionary]:
	if behavior_agent:
		return behavior_agent.get_overridable_property_list()
	return []

func _get(property: StringName) -> Variant:
	if behavior_agent:
		return behavior_agent.get_blackboard_property_value(property)
	return null

func _set(property: StringName, value: Variant) -> bool:
	if behavior_agent:
		if value is NodePath:
			value = behavior_agent.get_path_to(get_node(value))
		behavior_agent.set_blackboard_property(property,value)
		return true
	return false
