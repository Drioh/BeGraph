@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Particles Emitting"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a GPUParticles2D/3D or CPUParticles2D/3D) is currently emitting, branching to 'Emitting' or 'Not emitting'.\n\nFails if {node} can't be resolved or isn't a particle emitter."

func set_instruction() -> String:
	return "Check {node}'s emission state"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_particle_emitter(target):
		push_error("\"%s\" couldn't resolve a particle emitter" % resource_name)
		return Status.FAILURE

	if target.emitting:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Emitting",
		"Not emitting"
	])

## Returns [code]true[/code] if [param n] is one of the particle emitter classes this node supports.
func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D
