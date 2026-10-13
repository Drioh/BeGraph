@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Particles Emitting"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets or toggles the emitting state of a particle system node."

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON

func tick(_delta: float) -> Status:
	var target : Node = eval(&"node", true)
	if target == null or not _is_particle_emitter(target):
		return abort("couldn't resolve particle emitter")
		
	match eval(&"mode") as Mode:
		Mode.ON: target.emitting = true
		Mode.OFF: target.emitting = false
		Mode.TOGGLE: target.emitting = not target.emitting
		
	return Status.SUCCESS

func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D

func set_instruction() -> String: return "Set {node}'s emission: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
