@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Run Subgraph"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/run_subgraph_node_icon.svg"
const DISPLAY_INFO : String = "Runs another Behavior Graph ({subgraph}) inside this one, starting from the access point labelled {access_point} (empty = the first access point).\n\nReturns RUNNING while the subgraph is running, SUCCESS when it succeeds (then ticks its own successor) and FAILURE when it fails. The result of the subgraph is the status returned by the node linked to its access point, so use a Sequence/Selector as first node to get a meaningful result. After finishing, the subgraph restarts from scratch the next time it's ticked.\n\nIf {share_blackboard} is true, every blackboard variable of the subgraph with the same name as one of this graph's is shared with it (read and written live); the other variables stay local to the subgraph.\n\nFails if {subgraph} isn't set, has no matching access point, or subgraphs are nested too deeply (a graph must never contain itself)."

## Maximum nesting level of subgraphs, protects against a graph that (directly or not) contains itself.
const MAX_DEPTH : int = 16
## Meta key used to remember how deep a runtime graph is nested.
const DEPTH_META : StringName = &"begraph_subgraph_depth"

## Runtime copy of the subgraph. Kept here because nodes only hold weak references to their graph.
var _runtime_graph : BehaviorGraph = null
## Access point of [member _runtime_graph] the execution starts from.
var _entry : BehaviorNode = null

func set_instruction() -> String:
	return "Run subgraph {subgraph} from {access_point} (share blackboard: {share_blackboard})"

func tick(delta:float) -> Status:
	if dirty:
		if not _build_runtime_graph():
			return Status.FAILURE
		dirty = false

	var status : Status = _entry.tick_next(delta)
	if status == Status.RUNNING:
		return Status.RUNNING

	# Finished: drop the runtime copy so the next run starts from a clean state.
	_release_runtime_graph()
	if status == Status.SUCCESS:
		tick_next(delta)
		return Status.SUCCESS
	return Status.FAILURE

## Duplicates the subgraph, binds it to the owning agent, picks the entry point and (optionally) shares the blackboard. Returns [code]false[/code] on error.
func _build_runtime_graph() -> bool:
	var parent : BehaviorGraph = _graph_ref.get_ref()
	if parent == null:
		push_error("\"%s\" lost its graph reference" % resource_name)
		return false

	var agent : Node = get_agent()
	if agent == null:
		return false

	var source : BehaviorGraph = get("subgraph") as BehaviorGraph
	if source == null:
		push_error("\"%s\" has no subgraph set" % resource_name)
		return false

	var depth : int = int(parent.get_meta(DEPTH_META, 0)) + 1
	if depth > MAX_DEPTH:
		push_error("\"%s\": subgraphs nested more than %d levels deep (does a graph contain itself?)" % [resource_name, MAX_DEPTH])
		return false

	var runtime : BehaviorGraph = source.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as BehaviorGraph
	runtime.set_meta(DEPTH_META, depth)
	runtime.setup_runtime(agent)

	var entry : BehaviorNode = _find_entry(runtime, String(get("access_point")))
	if entry == null:
		push_error("\"%s\" couldn't find access point \"%s\" in subgraph" % [resource_name, get("access_point")])
		return false

	if get("share_blackboard") == true:
		_share_blackboard(parent, runtime)

	_runtime_graph = runtime
	_entry = entry
	return true

func _release_runtime_graph() -> void:
	_runtime_graph = null
	_entry = null
	dirty = true

## Returns the access point of [param graph] whose label (or node name) is [param wanted], or the first one if [param wanted] is empty.
func _find_entry(graph : BehaviorGraph, wanted : String) -> BehaviorNode:
	for n in graph.get_nodes_by_category("access_point_node"):
		var access_point : AccessPointNode = n as AccessPointNode
		if access_point == null:
			continue
		if wanted == "" or access_point.label == wanted or String(access_point.resource_name) == wanted:
			return access_point
	return null

## Replaces every variable of [param sub]'s blackboard that has the same name as one in [param parent]'s blackboard with the parent's instance, so both graphs read and write the very same value.
func _share_blackboard(parent : BehaviorGraph, sub : BehaviorGraph) -> void:
	for i in sub.blackboard.size():
		var sub_variable : BlackboardVariable = sub.blackboard[i]
		if sub_variable == null:
			continue
		for parent_variable in parent.blackboard:
			if parent_variable != null and parent_variable.name == sub_variable.name:
				sub.blackboard[i] = parent_variable
				break

func set_node_category()->String: return "run_subgraph_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("subgraph", null, PROPERTY_HINT_RESOURCE_TYPE, "BehaviorGraph", "", "BehaviorGraph", PROPERTY_USAGE_DEFAULT, TYPE_OBJECT)
	_add_behavior_property("access_point", &"")
	_add_behavior_property("share_blackboard", true)
