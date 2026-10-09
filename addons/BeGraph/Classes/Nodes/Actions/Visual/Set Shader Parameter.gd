@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Shader Parameter"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

const UNIQUE_META : StringName = &"begraph_unique_material"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"CanvasItem,GeometryInstance3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parameter : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var unique_material : bool = false

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not (target is CanvasItem or target is GeometryInstance3D):
		return abort("couldn't resolve CanvasItem or GeometryInstance3D")
		
	var material : Material = target.material if target is CanvasItem else target.material_override
	if eval(&"unique_material") and material != null and not target.has_meta(UNIQUE_META):
		material = material.duplicate()
		if target is CanvasItem: target.material = material
		else: target.material_override = material
		target.set_meta(UNIQUE_META, true)
		
	if not material is ShaderMaterial:
		return abort("node does not have a valid ShaderMaterial")
		
	material.set_shader_parameter(eval(&"parameter"), eval(&"value"))
	return tick_next(delta)

func set_instruction() -> String: return "Set {node}'s shader parameter {parameter} to {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
