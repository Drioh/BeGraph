@tool
## Runtime node that owns and drives a [BehaviorGraph]: it exposes which [AccessPointNode] to start from (via the dynamically-built [code]starting_point[/code] inspector enum) and ticks the resulting [member starting_node] every frame (or physics frame, or manually, depending on [member graph_process_mode]).
class_name BehaviorAgent
extends Node

## The thread/loop this agent's [BehaviorGraph] gets ticked on.
enum ProcessThread { IDLE, PHYSICS, MANUAL }

## Group every running [BehaviorAgent] adds itself to (outside the editor), used by debugging/visualization tools - e.g. the live graph debugger - to discover agents without needing a direct scene reference.
const DEBUG_GROUP : StringName = &"begraph_agents"

signal behavior_signal(args: Array)

@export_custom(PROPERTY_HINT_NONE,"",PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_STORAGE|PROPERTY_USAGE_READ_ONLY) var bb_props: Dictionary[StringName,Variant]

## If [code]false[/code], disables both [method Node._process] and [method Node._physics_process] ticking for this agent.
@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_process_flags()

## The [BehaviorGraph] this agent executes. Assigning a new value resets the selected starting point back to the graph's first access point.
@export var behavior_graph: BehaviorGraph:
	set(value):
		if behavior_graph == value: return
		behavior_graph = value
		_starting_point_idx = 0
		if behavior_graph != null:
			notify_property_list_changed.call_deferred()
var _behavior_graph : BehaviorGraph #duplicate

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
## [method Time.get_ticks_msec] timestamp of the last manual [method tick] call resolved with no explicit delta (i.e. called with the default [code]-1[/code]). Used by [method _resolve_delta] to compute a fallback per-tick delta for manual ticking; reset whenever an explicit delta is supplied instead, so switching back to delta-less ticking later doesn't report one huge elapsed gap.
var _manual_tick_time : int = -1

## Enables/disables [method Node._process] and [method Node._physics_process] based on [member enabled] and [member graph_process_mode].
func _update_process_flags() -> void:
	set_physics_process(enabled and graph_process_mode == ProcessThread.PHYSICS)
	set_process(enabled and graph_process_mode == ProcessThread.IDLE)

## Exposes the dynamic [code]starting_point[/code] enum property (its options are the labels of every access point found in [member behavior_graph]), used from the inspector to pick which entry point this agent starts ticking from.
func _get_property_list() -> Array[Dictionary]:
	if behavior_graph == null: return []
	
	var ret: Array[Dictionary] = []
	var nodes := behavior_graph.get_nodes_by_category("access_point_node")
	var labels := PackedStringArray()
	
	for node in nodes:
		# Fallback to the node name so an unlabeled access point still gets a readable, non-empty enum entry.
		var label : String = node.label if node.label != "" else String(node.resource_name)
		labels.append(label)
	
	ret.append({
		"name": "starting_point",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(labels),
		"usage": PROPERTY_USAGE_DEFAULT
	})
	ret.append_array(get_overridable_property_list())
	return ret

func _get(property: StringName) -> Variant:
	if property == "starting_point": return _starting_point_idx
	if not property.begins_with(BG.OBP): return null

	return bb_props[property]

func _set(property: StringName, value: Variant) -> bool:
	if property == "starting_point":
		_starting_point_idx = value
		return true
	
	if not property.begins_with(BG.OBP): return false
	bb_props[property] = value
	return true

## At runtime (not in the editor), validates that both [member behavior_graph] and [member starting_node] are set; disables this node entirely ([constant Node.PROCESS_MODE_DISABLED]) and logs an error otherwise. Also registers this agent in [constant DEBUG_GROUP] so runtime tools (e.g. the live graph debugger) can find it.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if behavior_graph == null:
		push_error("Behavior Graph not set for Behavior Agent %s" % self)
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	_behavior_graph = behavior_graph.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_behavior_graph.setup_runtime(self)
	_select_starting_node(_starting_point_idx)

	if starting_node == null:
		push_error("Starting Node not set for Behavior Agent %s" % self)
		process_mode = Node.PROCESS_MODE_DISABLED
		return
		
	add_to_group(DEBUG_GROUP)
	
	for p in bb_props:
		var v = get(p)
		if v == null: continue
		if v is NodePath and !v.is_absolute():
			v=get_node(v).get_path()
		set_blackboard_property(p, v)
	
## Resolves the delta (in seconds) to forward to [member starting_node] for one [method tick] call, used only by manual ticking ([constant ProcessThread.MANUAL]).[br]
## If [param delta] is anything other than [code]-1[/code], it's trusted and returned as-is: this is the case for an explicit delta passed to [method tick].[br]
## Otherwise (manual ticking with the default [code]-1[/code]), falls back to measuring the real time elapsed since the previous delta-less [method tick] call via [method Time.get_ticks_msec], returning [code]0.0[/code] on the first such call so nodes that accumulate elapsed time (e.g. [Wait], [Move], [Patrol]) start from zero instead of a huge spike.
func _resolve_delta(delta: float) -> float:
	if delta != -1.0:
		_manual_tick_time = -1
		return delta

	var now : int = Time.get_ticks_msec()
	if _manual_tick_time == -1:
		_manual_tick_time = now
		return 0.0

	var elapsed : float = (now - _manual_tick_time) / 1000.0
	_manual_tick_time = now
	return elapsed

## Ticks [member starting_node] every idle frame when [member graph_process_mode] is [constant ProcessThread.IDLE] (outside the editor).
func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not enabled: return
	if starting_node==null: return
	
	starting_node.do_tick(_delta)

## Ticks [member starting_node] every physics frame when [member graph_process_mode] is [constant ProcessThread.PHYSICS] (outside the editor), forwarding the engine's own physics delta directly (bypassing [method _resolve_delta], which only applies to manual ticking).
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	if not enabled: return
	if starting_node==null: return
	
	starting_node.do_tick(_delta)

## Manually ticks [member starting_node], provided [member enabled] is [code]true[/code]. Intended to be called by user code when [member graph_process_mode] is [constant ProcessThread.MANUAL].[br]
## [param delta] defaults to [code]-1[/code]: in that case [method _resolve_delta] falls back to the pre-existing [method Time.get_ticks_msec]-based system so time-based nodes keep working unattended. Pass an explicit delta (in seconds) to drive ticking with a known, fixed step instead.
func tick(_delta:float=-1.0) -> void:
	if not enabled: return
	if starting_node==null: return
	
	starting_node.do_tick(_resolve_delta(_delta))

## Resolves [member starting_node] from the access point at [param index] inside [member behavior_graph]'s [code]"access_point_node"[/code] category, or sets it to [code]null[/code] if [member behavior_graph] is unset, has no access points, or [param index] is out of range.
func _select_starting_node(index: int) -> void:
	if _behavior_graph == null:
		starting_node = null
		return

	var names := _behavior_graph.get_nodes_names_by_category("access_point_node")
	if names.is_empty():
		starting_node = null
		return

	if index >= 0 and index < names.size():
		starting_node = _behavior_graph.get_node(names[index])
	else:
		starting_node = null

##Returns [code]true[/code] if given [code]property[/code] is contained withing the [code]Blackboard[/code] associated with this [code]BehaviorAgent[/code]
func is_bb_property(property:StringName)->bool:
	return property.begins_with(BG.OBP)

func get_overridable_property_list()->Array[Dictionary]:
	var base_usage := PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_NIL_IS_VARIANT
	var ret : Array[Dictionary]
	for bb_var in behavior_graph.blackboard:
		if bb_var.export_variable:
			var name :String = BG.OBP+"/"+bb_var.name
			if name not in bb_props.keys():
				bb_props[name] = bb_var._value
				
			ret.append({
				"name": name,
				"type": typeof(bb_var._value),
				"hint": PROPERTY_HINT_NONE,
				"hint_string": "",
				"usage": base_usage
			})
	for bb_prop in bb_props.duplicate():
		if behavior_graph.get_blackboard_property(bb_prop.get_slice("/", 1))== null:
			bb_props.erase(bb_prop)
	return ret

func set_blackboard_property(key: StringName, value: Variant) -> bool:
	var graph : BehaviorGraph = _behavior_graph if _behavior_graph != null else behavior_graph
	
	var clean_key:StringName = BG.clean_key(key)

	if graph == null or graph.get_blackboard_property(clean_key) == null:
		return false
	graph.set_blackboard_value(clean_key, value)
	return true

func get_blackboard_property_value(key: StringName, default_value: Variant = null) -> Variant:
	var graph : BehaviorGraph = _behavior_graph if _behavior_graph != null else behavior_graph
	var clean_key:StringName = BG.clean_key(key)
	
	return graph.get_blackboard_value(clean_key, default_value) if graph != null else default_value

## Returns this agent's live, runtime-duplicated [BehaviorGraph] (the one actually being ticked via [method do_tick] each frame), for read-only inspection by external tools such as the live graph debugger. Returns [code]null[/code] before [method _ready] has run (e.g. in the editor, or before the game has started).
func get_debug_graph() -> BehaviorGraph:
	return _behavior_graph

func get_debug_graph_info() -> Dictionary:
	return {
		"name": behavior_graph.resource_name,
		"path": behavior_graph.resource_path
	}
