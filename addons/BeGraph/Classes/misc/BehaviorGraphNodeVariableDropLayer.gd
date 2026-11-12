@tool
class_name BehaviorGraphNodeVariableDropLayer
extends PanelContainer

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var p = get_parent()
	if p and p.has_method(&"_can_drop_data"):
		return p._can_drop_data(at_position, data)
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var p = get_parent()
	if p and p.has_method(&"_drop_data"):
		p._drop_data(at_position, data)
