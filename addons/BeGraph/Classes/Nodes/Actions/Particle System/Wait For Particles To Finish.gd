@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For Particles To Finish"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits until a particle system node finishes emitting."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D") var node : NodePath = NodePath("")

var _emitter : Node = null
var _finished : bool = false

func on_start() -> void:
	_finished = false
	_emitter = eval(&"node", true)
	if _emitter == null or not _is_particle_emitter(_emitter):
		abort("couldn't resolve particle emitter")
		return
		
	if not _emitter.finished.is_connected(_on_finished):
		_emitter.finished.connect(_on_finished, CONNECT_ONE_SHOT)

func tick(_delta: float) -> Status:
	if _finished:
		return Status.SUCCESS
	return Status.RUNNING

func _on_finished() -> void:
	_finished = true

func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D

func on_end(_status: Status) -> void:
	if _emitter != null and is_instance_valid(_emitter):
		if _emitter.finished.is_connected(_on_finished):
			_emitter.finished.disconnect(_on_finished)
	_emitter = null

func set_instruction() -> String: return "Wait for {node} to finish emitting"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
