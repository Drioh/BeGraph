@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For Particles To Finish"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits for {node} (a GPUParticles2D/3D or CPUParticles2D/3D) to emit its \"finished\" signal, returning RUNNING until it fires and SUCCESS afterwards.\n\nThat signal only fires once when {node}'s one_shot is enabled; with one_shot disabled this node never completes.\n\nFails if {node} can't be resolved or isn't a particle emitter."

var _connected_node : Node = null
var _finished : bool = false

func set_instruction() -> String:
	return "Wait for {node} to finish emitting"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_particle_emitter(target):
		push_error("\"%s\" couldn't resolve a particle emitter" % resource_name)
		return Status.FAILURE

	if _connected_node != target:
		_disconnect_signal()
		_connected_node = target
		_finished = false
		target.finished.connect(_on_finished, CONNECT_ONE_SHOT)

	if _finished:
		_disconnect_signal()
		tick_next(delta)
		return Status.SUCCESS

	return Status.RUNNING

func _on_finished() -> void:
	_finished = true

func _disconnect_signal() -> void:
	if _connected_node != null and is_instance_valid(_connected_node):
		if _connected_node.finished.is_connected(_on_finished):
			_connected_node.finished.disconnect(_on_finished)
	_connected_node = null

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

## Returns [code]true[/code] if [param n] is one of the particle emitter classes this node supports.
func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D
