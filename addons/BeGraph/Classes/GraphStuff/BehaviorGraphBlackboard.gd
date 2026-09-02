@tool
class_name BehaviorGraphBlackboard
extends Resource

##Array that contains all of the [BlackboardVariable]s
@export var content : Array[BlackboardVariable]:
	set(value):
		content=value
		emit_changed()

##Returns the value of a [BlackboardVariable] inside of [param content] based on given [code]key[/code].
func get_value(key: StringName) -> Variant:
	for entry in content:
		if key == entry.name: return entry.value
	push_error("key \"%s\" not found" % key)
	return null

##Returns [code]true[/code] if give [code]key[/code] can be found in [param content].
func has_value(key: StringName) -> bool:
	return content.has(key)

##Returns [code]true[/code] if manages to remove variable with given [code]key[/code] inside of [param content], [code]false[/code] otherwise.
func erase_value(key: StringName) -> bool:
	for entry in content:
		if key == entry.name: 
			content.erase(entry)
			return true
	push_error("key \"%s\" not found" % key)
	return false

##Returns [code]true[/code] if manages to set variable with given [code]key[/code] to [code]value[/code] inside of [param content], [code]false[/code] otherwise.
func set_value(key: StringName, value: Variant) -> bool:
	for entry in content:
		if key == entry.name: 
			entry.value=value
			return true
	push_error("key \"%s\" not found" % key)
	return false

##Returns the whole [BlackboardVariable] (name and value) corresponding to the given [code]name[/code], if present.
func get_variable(name:StringName) -> BlackboardVariable:
	for c in content:
		if c.name == name:
			return c
	return null

##Returns all of the names of the different variables inside [param content]
func get_keys() -> Array[StringName]:
	var out: Array[StringName] = []
	for entry in content:
		if entry:
			out.append(entry.name)
	return out

##Returns all of the values of the different variables inside [param content]
func get_values() -> Array[Variant]:
	var out: Array[StringName] = []
	for entry in content:
		out.append(entry.value)
	return out
