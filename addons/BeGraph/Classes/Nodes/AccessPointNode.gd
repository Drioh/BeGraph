class_name AccessPointNode
extends BehaviorNode

const DISPLAY_NAME : String = "Access Point"

func set_instruction() -> String:
	return "Access Point: {label}"

func tick() -> Status:
	return Status.RUNNING

func set_node_category()->String:return "access_point_node"

func set_input()->bool:return false

func set_output()->bool:return true

func set_resource_name()->String: return "Access Point"

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> Array[Dictionary]:
	return [_add_behavior_property("label",TYPE_STRING)]
