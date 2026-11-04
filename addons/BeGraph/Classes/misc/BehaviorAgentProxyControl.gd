@tool
extends Control
class_name BehaviorAgentProxyControl

@export var behavior_agent: BehaviorAgent
@export var allowed_list : Dictionary[StringName,bool]:
	set(value):
		if value and value.size()==allowed_list.size():
			allowed_list = value
			notify_property_list_changed()

func _get_property_list() -> Array[Dictionary]:
	if behavior_agent == null: return []
	
	var list: Array[Dictionary] = behavior_agent.get_overridable_property_list()
	var ret: Array[Dictionary]
	for item in list:
		if !allowed_list.get_or_add(item["name"],false): continue #both sets the dictionary and checks if the associated value to item["name"] is true or false
		ret.append(item)
	return ret

func _get(property: StringName) -> Variant:
	if behavior_agent == null: return null
	
	return behavior_agent.bb_props.get(property) #returns either the value or null, if the key "property" does not exist in bb_props

func _set(property: StringName, value: Variant) -> bool:
	if behavior_agent == null : return false
	if !behavior_agent.bb_props.has(property): return false
	
	if value is NodePath:
		value = behavior_agent.get_path_to(get_node(value)) #getting a path relative to the agent, for node resolution purposes
	behavior_agent.bb_props[property]=value
	return true
