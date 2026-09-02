@tool
class_name BlackboardVariable
extends Resource

@export var name: StringName = &""
@export var value : Variant:
	set(v):
		value = v
		emit_changed()
