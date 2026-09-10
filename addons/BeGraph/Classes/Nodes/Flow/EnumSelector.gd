@tool
class_name EnumSelectorNode
extends BehaviorNode

const DISPLAY_NAME : String = "Enum Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

func set_instruction() -> String:
	return "Enum Selector: {value}"

func tick() -> Status:
	var value : int = get("value")
	if value < 0 or value >= conditions.size():
		return Status.FAILURE
	var next_node : BehaviorNode = conditions[value]["next"]
	if next_node == null:
		return Status.FAILURE
	return next_node.tick()

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	## Editabile dall'Inspector (pulsante matita sul titlebar del nodo):
	## aggiungi, rimuovi, rinomina o riordina le voci liberamente.
	_add_behavior_property("enum_values", PackedStringArray(["Value 0", "Value 1"]))
	_add_behavior_property("value", 0, PROPERTY_HINT_ENUM, "Value 0,Value 1")

func set_conditions() -> PackedStringArray:
	return PackedStringArray(["Value 0", "Value 1"])

## Intercetta le modifiche a "enum_values" per tenere sincronizzati sia il
## dropdown di "value" sia le porte di output (conditions).
func _set(property: StringName, value: Variant) -> bool:
	var previous_size : int = -1
	if property == "enum_values":
		previous_size = get("enum_values").size()
		_sync_from_enum_values(previous_size)
		return true
	return false

func _sync_from_enum_values(previous_size: int = -1) -> void:
	var values : PackedStringArray = get("enum_values")
	if values.is_empty():
		values = PackedStringArray(["Value 0"])

	for prop in behavior_properties:
		if prop["name"] == "value":
			prop["hint_string"] = ",".join(values)
			if int(prop["value"]) >= values.size():
				prop["value"] = 0

	var old_conditions : Array[Dictionary] = conditions.duplicate(true)
	conditions.clear()
	for i in values.size():
		var kept_next : BehaviorNode = old_conditions[i]["next"] if i < old_conditions.size() else null
		conditions.append({"text": values[i], "next": kept_next})

	output = false
	conditions_changed.emit()   # aggiorna solo le righe/porte del GraphNode: non tocca l'Inspector

	# Il dropdown di "value" legge hint_string solo quando l'Inspector viene
	# ricostruito: lo facciamo SOLO quando la dimensione dell'array cambia,
	# mai durante la digitazione di un singolo elemento.
	if previous_size != -1 and previous_size != values.size():
		notify_property_list_changed.call_deferred()
