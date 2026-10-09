@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Restart Particles"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null or not _is_particle_emitter(target):
		return abort("couldn't resolve particle emitter")
		
	target.restart()
	return tick_next(delta)

func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D

func set_instruction() -> String: return "Restart particles {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
