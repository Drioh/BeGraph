@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Particles Emitting"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether a particle emitter node is currently emitting particles."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D") var node : NodePath = NodePath("")

var _target : Node = null

func on_start() -> void:
	_target = eval(&"node", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true)

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target) or not _is_particle_emitter(_target):
		return abort("couldn't resolve particle emitter")
		
	return tick_condition(delta, 0 if _target.emitting else 1)

func on_end(_status: Status) -> void:
	_target = null

func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D

func set_instruction() -> String: return "Check {node}'s emission state"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Emitting", "Not emitting"])
