@tool
class_name BlackboardVariable
extends Resource

signal name_changed(new_name: String)
signal value_changed(new_value: Variant)

@export var name: StringName = &"":
	set(v):
		name = v
		name_changed.emit(name)
@export var export_variable : bool = false

var _value: Variant = null


func _get_property_list() -> Array[Dictionary]:
	var base_usage := PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE

	return [{
		"name": "value",
		"type": TYPE_NIL, # forzato a NIL: mantiene il picker "convert to..." per gli altri tipi
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": base_usage | PROPERTY_USAGE_NIL_IS_VARIANT,
	}]

func _get(property: StringName) -> Variant:
	if property == "value":
		return _value
	return null

func _set(property: StringName, v: Variant) -> bool:
	if property == "value":
		var was_node_path := typeof(_value) == TYPE_NODE_PATH
		_value = v
		value_changed.emit(_value)
		if was_node_path != (typeof(_value) == TYPE_NODE_PATH):
			notify_property_list_changed.call_deferred()
		return true
	return false
