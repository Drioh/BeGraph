@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Particles Emitting"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Turns emission on {node} (a GPUParticles2D/3D or CPUParticles2D/3D) on, off, or toggles it, depending on {mode}.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a particle emitter."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Set {node}'s emission: {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_particle_emitter(target):
		push_error("\"%s\" couldn't resolve a particle emitter" % resource_name)
		return Status.FAILURE

	match get("mode"):
		Mode.ON:
			target.emitting = true
		Mode.OFF:
			target.emitting = false
		Mode.TOGGLE:
			target.emitting = not target.emitting

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")

## Returns [code]true[/code] if [param n] is one of the particle emitter classes this node supports.
func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D
