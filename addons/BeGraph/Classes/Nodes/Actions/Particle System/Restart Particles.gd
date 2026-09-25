@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Restart Particles"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Restarts {node} (a GPUParticles2D/3D or CPUParticles2D/3D): clears its existing particles and restarts its emission cycle from scratch. Handy for retriggering a one-shot effect.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a particle emitter."

func set_instruction() -> String:
	return "Restart particles {node}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_particle_emitter(target):
		push_error("\"%s\" couldn't resolve a particle emitter" % resource_name)
		return Status.FAILURE

	target.restart()
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "GPUParticles2D,GPUParticles3D,CPUParticles2D,CPUParticles3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

## Returns [code]true[/code] if [param n] is one of the particle emitter classes this node supports.
func _is_particle_emitter(n: Node) -> bool:
	return n is GPUParticles2D or n is GPUParticles3D or n is CPUParticles2D or n is CPUParticles3D
