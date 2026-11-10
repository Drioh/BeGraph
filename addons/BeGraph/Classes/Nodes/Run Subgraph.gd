@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Run Subgraph"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/run_subgraph_node_icon.svg"
const DISPLAY_INFO : String = "Runs another Behavior Graph ({subgraph}) inside this one."

const MAX_DEPTH : int = 16
const DEPTH_META : StringName = &"begraph_subgraph_depth"

@export_custom(PROPERTY_HINT_RESOURCE_TYPE, BG.PROPERTY + "BehaviorGraph",) var subgraph : BehaviorGraph = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var access_point : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var share_blackboard : bool = true

var _cache_key : Array = [] # [subgraph_resource, access_point_wanted]
var _cached_runtime : BehaviorGraph = null
var _runtime_graph : BehaviorGraph = null
var _entry : BehaviorNode = null

func on_start() -> void:
	if not _build_runtime_graph():
		abort("couldn't build runtime subgraph")

func tick(delta: float) -> Status:
	if _entry == null:
		return Status.FAILURE
		
	var status : Status = _entry.tick_next(delta)
	if status == Status.RUNNING:
		return Status.RUNNING
		
	return status

func on_end(_status: Status) -> void:
	_release_runtime_graph()

func _on_abort_running(visited: Dictionary) -> void:
	if _entry != null:
		_entry.abort_running(visited)
	_release_runtime_graph()

func _build_runtime_graph() -> bool:
	var parent : BehaviorGraph = get_graph()
	if parent == null:
		return false
	var agent : Node = get_agent()
	if agent == null:
		return false

	var source : BehaviorGraph = eval(&"subgraph") as BehaviorGraph
	if source == null:
		return false

	var depth : int = int(parent.get_meta(DEPTH_META, 0)) + 1
	if depth > MAX_DEPTH:
		return false

	var wanted : String = String(eval(&"access_point"))
	var key : Array = [source, wanted]

	var runtime : BehaviorGraph
	if _cache_key == key and _cached_runtime != null:
		runtime = _cached_runtime
		# Reset node states as if it was the first execution
		for n : BehaviorNode in runtime.nodes.values():
			n.last_status = -1
	else:
		runtime = source.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as BehaviorGraph
		runtime.setup_runtime(agent, source)
		_cached_runtime = runtime
		_cache_key = key

	runtime.set_meta(DEPTH_META, depth)

	var entry : BehaviorNode = _find_entry(runtime, wanted)
	if entry == null:
		return false

	if eval(&"share_blackboard") == true:
		_share_blackboard(parent, runtime)
		runtime._rebuild_blackboard_map()

	_runtime_graph = runtime
	_entry = entry
	return true

func _release_runtime_graph() -> void:
	_runtime_graph = null
	_entry = null
	# _cached_runtime is retained for subsequent cycles

func _find_entry(graph : BehaviorGraph, wanted : String) -> BehaviorNode:
	for n in graph.get_nodes_by_category("access_point_node"):
		var access_point_node : AccessPointNode = n as AccessPointNode
		if access_point_node == null: continue
		if wanted == "" or access_point_node.label == wanted or String(access_point_node.resource_name) == wanted:
			return access_point_node
	return null

func _share_blackboard(parent : BehaviorGraph, sub : BehaviorGraph) -> void:
	for i in sub.blackboard.size():
		var sub_variable : BlackboardVariable = sub.blackboard[i]
		if sub_variable == null: continue
		for parent_variable in parent.blackboard:
			if parent_variable != null and parent_variable.name == sub_variable.name:
				sub.blackboard[i] = parent_variable
				break

func set_instruction() -> String: return "Run subgraph {subgraph} from {access_point} (share blackboard: {share_blackboard})"
func set_node_category() -> String: return "run_subgraph_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
