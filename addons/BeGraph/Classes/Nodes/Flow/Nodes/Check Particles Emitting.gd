@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Particles Emitting"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not _is_particle_emitter(target):
		return abort("couldn't resolve particle emitter")
		
	tick_condition(delta, 0 if target.emitting else 1)
	return Status.RUNNING

func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D

func set_instruction() -> String: return "Check {node}'s emission state"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Emitting", "Not emitting"])
