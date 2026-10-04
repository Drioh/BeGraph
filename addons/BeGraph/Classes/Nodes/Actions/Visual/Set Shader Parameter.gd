@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Shader Parameter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the shader uniform {parameter} of the ShaderMaterial of {node} to {value}. For a CanvasItem the 'material' property is used; for a GeometryInstance3D, 'material_override'.\n\nMaterials are usually shared between all the nodes that use them: if {unique_material} is true, {node}'s material is duplicated the first time, so the change only affects this node.\n\nSucceeds once applied; fails if {node} can't be resolved or doesn't have a ShaderMaterial."

const UNIQUE_META : StringName = &"begraph_unique_material"

func set_instruction() -> String:
	return "Set {node}'s shader parameter {parameter} to {value}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not (target is CanvasItem or target is GeometryInstance3D):
		push_error("\"%s\" couldn't resolve a CanvasItem or GeometryInstance3D" % resource_name)
		return Status.FAILURE

	var material : Material = _get_material(target)
	if get("unique_material") and material != null and not target.has_meta(UNIQUE_META):
		material = material.duplicate()
		_set_material(target, material)
		target.set_meta(UNIQUE_META, true)

	if not material is ShaderMaterial:
		push_error("\"%s\": \"%s\" doesn't have a ShaderMaterial" % [resource_name, target])
		return Status.FAILURE

	material.set_shader_parameter(get("parameter"), get("value"))
	tick_next(delta)
	return Status.SUCCESS

func _get_material(target : Node) -> Material:
	if target is CanvasItem:
		return target.material
	return target.material_override

func _set_material(target : Node, material : Material) -> void:
	if target is CanvasItem:
		target.material = material
	else:
		target.material_override = material

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("parameter", &"")
	_add_behavior_property("value", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("unique_material", false)
