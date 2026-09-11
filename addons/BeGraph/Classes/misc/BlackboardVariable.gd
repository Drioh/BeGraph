@tool
class_name BlackboardVariable
extends Resource

signal name_changed(new_name:String)
signal value_changed(new_value:Variant)

@export var name: StringName = &"":
	set(v):
		name = v
		name_changed.emit(name)
@export var value : Variant:
	set(v):
		value = v
		value_changed.emit(value)
