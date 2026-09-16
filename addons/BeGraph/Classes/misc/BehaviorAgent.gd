@tool
## Runtime node that owns and drives a [BehaviorGraph]: it exposes which [AccessPointNode] to start from (via the dynamically-built [code]starting_point[/code] inspector enum) and ticks the resulting [member starting_node] every frame (or physics frame, or manually, depending on [member graph_process_mode]).
class_name BehaviorAgent
extends Node

## The thread/loop this agent's [BehaviorGraph] gets ticked on.
enum ProcessThread { IDLE, PHYSICS, MANUAL }
## Mirrors [enum BehaviorNode.Status]; the result of a single [method tick].
enum Status { SUCCESS, FAILURE, RUNNING }

signal behavior_signal(args: Array)


## If [code]false[/code], disables both [method Node._process] and [method Node._physics_process] ticking for this agent.
@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_process_flags()

## The [BehaviorGraph] this agent executes. Assigning a new value resets the selected starting point back to the graph's first access point.
@export var behavior_graph: BehaviorGraph:
	set(value):
		if behavior_graph == value:
			return
		behavior_graph = value
		_starting_point_idx = 0
		_select_starting_node(_starting_point_idx)
		notify_property_list_changed.call_deferred()

## Which loop drives this agent's ticking. Setting this to [constant ProcessThread.MANUAL] also disables [member enabled], since manual mode expects [method tick] to be called explicitly by user code.
@export var graph_process_mode: ProcessThread = ProcessThread.IDLE:
	set(value):
		graph_process_mode = value
		if graph_process_mode == ProcessThread.MANUAL:
			enabled = false
		_update_process_flags()

## Index of the currently selected access point inside [code]behavior_graph.get_nodes_by_category("access_point_node")[/code], backing the dynamically-built [code]starting_point[/code] inspector enum.
var _starting_point_idx: int = 0
## The [BehaviorNode] (the chosen access point's entry into the graph) that gets ticked by [method _process] / [method _physics_process] / [method tick].
var starting_node: BehaviorNode = null


## Enables/disables [method Node._process] and [method Node._physics_process] based on [member enabled] and [member graph_process_mode].
func _update_process_flags() -> void:
	set_physics_process(enabled and graph_process_mode == ProcessThread.PHYSICS)
	set_process(enabled and graph_process_mode == ProcessThread.IDLE)


## Exposes the dynamic [code]starting_point[/code] enum property (its options are the names of every access point found in [member behavior_graph]), used from the inspector to pick which entry point this agent starts ticking from.
func _get_property_list() -> Array[Dictionary]:
	var ret: Array[Dictionary] = []
	if behavior_graph != null:
		var nodes := behavior_graph.get_nodes_by_category("access_point_node")
		var hint_string := ""
		for node in nodes:
			hint_string = ",".join(PackedStringArray([node.label]))
		ret.append({
			"name": "starting_point",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": hint_string,
			"usage": PROPERTY_USAGE_DEFAULT
		})
	return ret


## Overrides [method Object._get] to back the dynamic [code]starting_point[/code] property with [member _starting_point_idx].
func _get(property: StringName) -> Variant:
	if property == "starting_point":
		return _starting_point_idx
	return null

## Overrides [method Object._set] to update [member _starting_point_idx] and re-resolve [member starting_node] whenever [code]starting_point[/code] is changed from the inspector.
func _set(property: StringName, value: Variant) -> bool:
	if property == "starting_point":
		_starting_point_idx = value
		_select_starting_node(_starting_point_idx)
		return true
	return false

## At runtime (not in the editor), validates that both [member behavior_graph] and [member starting_node] are set; disables this node entirely ([constant Node.PROCESS_MODE_DISABLED]) and logs an error otherwise.
func _ready() -> void:
	if not Engine.is_editor_hint():
		if behavior_graph == null:
			push_error("Behavior Graph not set for Behavior Agent %s" % self)
			process_mode = Node.PROCESS_MODE_DISABLED
			return
		
		for c in behavior_graph.connections:
			var from_node : BehaviorNode = behavior_graph.get_node(c["from_node"])
			var to_node : BehaviorNode = behavior_graph.get_node(c["to_node"])
			if from_node == null or to_node == null:
				push_error("Impossibile ricostruire la connessione %s -> %s" % [c["from_node"], c["to_node"]])
				continue
			from_node.add_next(to_node, c["from_port"])
		
		if starting_node == null:
			push_error("Starting Node not set for Behavior Agent %s" % self)
			process_mode = Node.PROCESS_MODE_DISABLED
			return
		for node in behavior_graph.nodes.values():
			node._graph_ref = weakref(behavior_graph)
			

## Ticks [member starting_node] every idle frame when [member graph_process_mode] is [constant ProcessThread.IDLE] (outside the editor).
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() && enabled:
		if starting_node != null:
			starting_node.tick()

## Ticks [member starting_node] every physics frame when [member graph_process_mode] is [constant ProcessThread.PHYSICS] (outside the editor).
func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() && enabled:
		if starting_node != null:
			starting_node.tick()


## Manually ticks [member starting_node], provided [member enabled] is [code]true[/code]. Intended to be called by user code when [member graph_process_mode] is [constant ProcessThread.MANUAL].
func tick() -> void:
	if enabled and starting_node != null:
		starting_node.tick()

## Resolves [member starting_node] from the access point at [param index] inside [member behavior_graph]'s [code]"access_point_node"[/code] category, or sets it to [code]null[/code] if [member behavior_graph] is unset, has no access points, or [param index] is out of range.
func _select_starting_node(index: int) -> void:
	if behavior_graph == null:
		starting_node = null
		return

	var names := behavior_graph.get_nodes_names_by_category("access_point_node")
	if names == null:
		starting_node = null
		return

	if index >= 0 and index < names.size():
		starting_node = behavior_graph.get_node(names[index])
	else:
		starting_node = null
