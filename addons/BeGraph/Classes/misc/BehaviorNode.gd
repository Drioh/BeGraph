@tool
@abstract class_name BehaviorNode
extends Resource

## The abstract class every node written for the BeGraph plugin must extend.[br]
##To show a custom name and icon, a node must define the [code]DISPLAY_NAME[/code] and the the [code]DISPLAY_ICON[/code] String constants.[br]

## Return value for the [method tick] method.
enum Status{SUCCESS,FAILURE,RUNNING,ERROR}

## Property usage flags shared by every internal/read-only field of this resource (storage + read-only + editor visible, but not user-editable).
const INTERNAL_USAGE := PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR

## Describes what the node does. Logic to determine which node is next in execution is written here.[br]
## Never call this directly from outside the node: successors are ticked through [method tick_next]/[method tick_condition] (or, for the graph's starting node, by [BehaviorAgent]), which route through [method do_tick] instead so its execution can be tracked (e.g. by the live graph debugger).
@abstract func tick(delta:float) -> Status

## Called once when node starts execution (when it goes from non-RUNNING to tick).
func on_start() -> void: pass

## Called once when node ends execution (returns SUCCESS o FAILURE).
func on_end(status: Status) -> void: pass

## interrupts node execution if int RUNNING state (used when a parent aborts an active branch).
func abort(error_msg: String = "") -> Status:
	if not error_msg.is_empty():
		push_error("BehaviorNode '%s' (%s): %s" % [resource_name, get_script().resource_path.get_file(), error_msg])
	return Status.ERROR

## The line displayed in the node. use [code]{}[/code] annotation to declare variables.
@abstract func set_instruction() -> String

## If set to [code]true[/code], allows this node to have a predecessor.
func set_input()->bool : return true

## If set to [code]true[/code], allows this node to have a successor. [br]
## If conditions are set, this gets automatically set to [code]false[/code].
func set_output()->bool : return true


func set_mutable()->bool : return true

func set_breakpointable()->bool:return true
## If set to [code]true[/code], allows this node to have multiple successors, while, if set to [code]false[/code], allows only for one successor.
@abstract func set_allows_multiple_outputs() -> bool

## Instruction displayed in node. To set this parameter, use the [method set_instruction] method
@export_custom(PROPERTY_HINT_MULTILINE_TEXT, "", INTERNAL_USAGE)var instruction : String = ""

@export_group("Debug")

## Defines multiple successors for this node depending on the logic of the node itself. To set conditions, use the [method set_conditions] method, providing a [code]PackedStringArray[/code].[br]Conditions can have only one successor.[br]
## Example:[br][codeblock]
##func set_conditions() -> PackedStringArray:
##    return PackedStringArray([
##        "{value_1} > {value_2}",
##        "{value_1} = {value_2}",
##        "{value_1} < {value_2}"
##    ])
##[/codeblock]
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE)var conditions : Array[Dictionary]

## For display purposes only, this parameter defines a node's category. Set using [method set_node_category].
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE)var node_category : String = ""

## Regular expression used to get variables from the text.
var regex :RegEx= RegEx.create_from_string(r"\{([^{}]+)\}")

## If [code]true[/code], lets the node have one or more predecessor(s).
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var input : bool = false

## If [code]true[/code], lets the node have one or more, depending on [param allows_multiple_outputs] successor(s).
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var output : bool = false

## If [code]true[/code], lets the node have more than one successor per output slot ([param _next_ref] is allowed to have a size greater than 0).
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE)var allows_multiple_outputs : bool = false

## Position of this node inside the [BehaviorGraphEdit] canvas, in local graph coordinates. Kept in sync with the visual [GraphNode] via [signal GraphNode.position_offset_changed].
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE) var position_in_graph : Vector2

## Returns [code]true[/code] if this node belongs to the [code]"access_point_node"[/code] category, meaning it can be used as an entry point by a [BehaviorAgent].
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE) var is_starting_node : bool :
	get():
		if node_category == "access_point_node": 
			return true
		return false

## Weak reference to the [BehaviorGraph] this node belongs to. Used to resolve blackboard bindings and to notify the graph of connection changes.
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE) var _graph_ref : WeakRef

## Weak references to this node's successor(s), used when [member output] is [code]true[/code].
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE) var _next_ref : Array[StringName]

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
var _blackboard_bindings: Dictionary[StringName, StringName] = {}

@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE) var breakpoint_enabled : bool = false

@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE) var mute_enabled : bool = false

## Emitted whenever a property's blackboard binding is enabled or disabled via [method set_node_property_blackboard_key].
signal blackboard_key_set(property:StringName,blackboard_key:StringName)

## Emitted whenever [member conditions] is rebuilt (e.g. after an enum-based property changes its number of entries).
signal conditions_changed

## Emitted right after this node runs (see [method do_tick]), carrying the resulting [enum Status]. Meant for debugging/visualization tools (e.g. the live graph debugger); nothing in the plugin's own execution logic depends on it.
signal ticked(status:Status)

## The [enum Status] returned by this node's last [method do_tick] call, or [code]-1[/code] if it has never been ticked.
var last_status : int = -1
## [method Time.get_ticks_msec] timestamp of this node's last [method do_tick] call, or [code]-1[/code] if it has never been ticked.
var last_tick_time : int = -1

#region Decorator

## Decorator applied to this node's execution, only meaningful on nodes for which [method supports_decorator] returns true (any category except "access_point_node", with output enabled and no conditions). Read-only in the default inspector: edited through the node's own Tree UI (see [code]BehaviorGraphNode.gd[/code] / [code]%DecoratorTree[/code]) via [method set_decorator_type] and [method set_decorator_field].[br]
## Fields, used depending on [code]type[/code]:[br]
## - [code]type[/code]: [code]"none"[/code], [code]"inverter"[/code], [code]"force"[/code], [code]"repeater"[/code], [code]"time_limit"[/code], [code]"cooldown"[/code], [code]"delay"[/code], [code]"condition"[/code].[br]
## - [code]variant[/code]: [code]force[/code] (0 Success / 1 Failure) or [code]repeater[/code] (0 Times / 1 Until Success / 2 Until Failure).[br]
## - [code]seconds[/code]: main duration for [code]time_limit[/code] / [code]cooldown[/code] / [code]delay[/code].[br]
## - [code]count[/code]: [code]repeater[/code] in Times mode - number of attempts, [code]0[/code] = infinite.[br]
## - [code]timeout[/code]: [code]repeater[/code] in Until* mode - seconds before giving up, [code]0[/code] = infinite (same convention as [code]Wait Until.gd[/code]).[br]
## - [code]between_delay[/code]: [code]repeater[/code] - seconds to wait between one attempt and the next, [code]0[/code] = no wait.[br]
## - [code]on_timeout[/code]: [code]time_limit[/code] child - 0 Abort / 1 Let Run.[br]
## - [code]cooldown_mode[/code]: [code]cooldown[/code] child - 0 Always / 1 On Success.[br]
## - [code]delay_mode[/code]: [code]delay[/code] child - 0 Before / 1 After.[br]
## - [code]blackboard_key[/code]: [code]condition[/code] - name of the (boolean) [BlackboardVariable] dropped onto it.
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE) var decorator : Dictionary = {
	"type": "none",
	"variant": 0,
	"seconds": 0.0,
	"count": 3,
	"timeout": 0.0,
	"between_delay": 0.0,
	"on_timeout": 0,
	"cooldown_mode": 0,
	"delay_mode": 0,
	"blackboard_key": &"",
}

## Every valid value for [code]decorator.type[/code] (the order the Tree UI lists them in, "none" aside).
const DECORATOR_TYPES : PackedStringArray = ["none", "inverter", "force", "repeater", "time_limit", "cooldown", "delay", "condition"]

## Field defaults applied by [method set_decorator_type] whenever [member decorator] switches to a given type - only the fields that type actually reads.
const DECORATOR_DEFAULTS : Dictionary = {
	"none": {},
	"inverter": {},
	"force": {"variant": 0},
	"repeater": {"variant": 0, "count": 3, "timeout": 0.0, "between_delay": 0.0},
	"time_limit": {"seconds": 5.0, "on_timeout": 0},
	"cooldown": {"seconds": 2.0, "cooldown_mode": 0},
	"delay": {"seconds": 1.0, "delay_mode": 0},
	"condition": {"blackboard_key": &""},
}

## Emitted whenever [member decorator] changes (type or a single field), so the node's Tree UI can re-sync itself.
signal decorator_changed

## Generic single-purpose timer, reused across whichever decorator family is active (only one
## can be active per node): elapsed time for Time Limiter / Cooldown-active-wait / Delay, and
## the wait between one Repeater attempt and the next.
var _dec_elapsed : float = 0.0
## Repeater only: total elapsed time since the current repeat pass started; drives the Until* timeout.
var _dec_repeat_elapsed : float = 0.0
## Repeater only: attempts completed so far in the current Times pass.
var _dec_attempts : int = 0
## Repeater only: true while waiting out [code]between_delay[/code] before the next attempt.
var _dec_waiting_between : bool = false
## Repeater only: true right after an attempt ends and another one is coming - tells
## [method _decorator_repeater] to call [method on_start] once before ticking again, since
## [method do_tick] itself only does that at the start of a whole execution cycle.
var _dec_repeat_restart_pending : bool = false
## Cooldown only: seconds left before this node can run again, [code]-1[/code] = not on cooldown.
## Deliberately NOT reset by [method _reset_decorator_state]: a cooldown must survive across
## separate execution cycles of this node, the same way [code]Cooldown.gd[/code]'s own
## [code]_cooldown_remaining[/code] does.
var _dec_cooldown_remaining : float = -1.0
## Delay ("After") only: the real status being held back while [code]seconds[/code] elapses, [code]-1[/code] = none pending.
var _dec_delayed_status : int = -1


## Resets every [code]_dec_*[/code] runtime variable that belongs to a single execution cycle. Called by [method do_tick] whenever this node restarts (i.e. it wasn't RUNNING last frame), right before [method on_start]. Never touches anything belonging to the action itself.
func _reset_decorator_state() -> void:
	_dec_elapsed = 0.0
	_dec_repeat_elapsed = 0.0
	_dec_attempts = 0
	_dec_waiting_between = false
	_dec_repeat_restart_pending = false
	_dec_delayed_status = -1

## Switches [member decorator] to [param type], resetting its fields to [constant DECORATOR_DEFAULTS] for that type. Called by the node's Tree UI when a different decorator family gets checked.
func set_decorator_type(type: String) -> void:
	var fresh : Dictionary = {"type": type}
	fresh.merge(DECORATOR_DEFAULTS.get(type, {}), true)
	decorator = fresh
	_reset_decorator_state()
	decorator_changed.emit()
	emit_changed()

## Sets a single [member decorator] field (e.g. [code]"seconds"[/code]) without touching the others or the runtime state. Called by the Tree UI's inline cell editors.
func set_decorator_field(field: StringName, value: Variant) -> void:
	decorator[field] = value
	decorator_changed.emit()
	emit_changed()



## Inverter: ticks the action and swaps SUCCESS/FAILURE; RUNNING (and ERROR) pass through unchanged.
func _decorator_inverter(delta: float) -> Status:
	var status : Status = tick(delta)
	match status:
		Status.SUCCESS: return Status.FAILURE
		Status.FAILURE: return Status.SUCCESS
		_: return status

## Force: ticks the action; once it stops RUNNING, replaces SUCCESS/FAILURE with the fixed result picked by [code]decorator.variant[/code] (0 Success / 1 Failure). ERROR is left untouched, since it signals a genuine abort rather than a regular outcome.
func _decorator_force(delta: float) -> Status:
	var status : Status = tick(delta)
	if status == Status.RUNNING or status == Status.ERROR:
		return status
	return Status.SUCCESS if int(decorator.get("variant", 0)) == 0 else Status.FAILURE

## Repeater: unifies "repeat N times" and "repeat until SUCCESS/FAILURE" into a single decorator.[br]
## [code]decorator.variant[/code]: 0 Times (uses [code]count[/code], [code]0[/code] = infinite), 1 Until Success, 2 Until Failure (both use [code]timeout[/code] seconds, [code]0[/code] = infinite; times out as FAILURE).[br]
## If [code]decorator.between_delay[/code] is [code]> 0[/code], waits that many seconds between one attempt and the next before ticking the action again.[br]
## [b]Note:[/b] like [code]Repeat.gd[/code], this calls [method tick] several times before reporting a final outcome, and the action's own forward propagation (if it calls [method tick_next] itself) fires on every single attempt. A node carrying this decorator should therefore be a dead end in the graph (no outgoing connection) - document this in its [code]DISPLAY_INFO[/code].
func _decorator_repeater(delta: float) -> Status:
	var variant : int = int(decorator.get("variant", 0))
	var between_delay : float = decorator.get("between_delay", 0.0) as float

	# Waiting out the delay between one attempt and the next.
	if _dec_waiting_between:
		_dec_elapsed += delta
		if _dec_elapsed < between_delay:
			return Status.RUNNING
		_dec_waiting_between = false
		_dec_elapsed = 0.0

	# Start a fresh attempt (skipped on the very first one: do_tick() already called on_start()
	# once before _tick_with_decorator() was ever reached).
	if _dec_repeat_restart_pending:
		_dec_repeat_restart_pending = false
		on_start()

	_dec_repeat_elapsed += delta
	var status : Status = tick(delta)

	if status == Status.RUNNING or status == Status.ERROR:
		return status

	var done : bool = false
	match variant:
		0: # Times
			_dec_attempts += 1
			var total : int = int(decorator.get("count", 3))
			done = total > 0 and _dec_attempts >= total
		1: done = status == Status.SUCCESS # Until Success
		2: done = status == Status.FAILURE # Until Failure

	var timeout : float = decorator.get("timeout", 0.0) as float
	var timed_out : bool = variant != 0 and timeout > 0.0 and _dec_repeat_elapsed >= timeout

	if done:
		return status
	if timed_out:
		return Status.FAILURE

	# One more attempt coming, optionally behind a between-attempts wait.
	_dec_repeat_restart_pending = true
	if between_delay > 0.0:
		_dec_waiting_between = true
		_dec_elapsed = 0.0
	return Status.RUNNING

## Time Limiter: ticks the action, but forces FAILURE once [code]decorator.seconds[/code] elapses without it finishing.[br]
## [code]decorator.on_timeout[/code]: 0 Abort forces the action to be fully reinitialized the next time it runs; 1 Let Run leaves the action's own in-progress state (e.g. a running [Tween]) survives to pick back up from where it was if this node runs again later.
func _decorator_time_limit(delta: float) -> Status:
	_dec_elapsed += delta
	var limit : float = decorator.get("seconds", 0.0) as float

	if limit > 0.0 and _dec_elapsed >= limit:
		return Status.FAILURE

	return tick(delta)

## Cooldown: once the action finishes (always, or only on SUCCESS, depending on [code]decorator.cooldown_mode[/code]: 0 Always / 1 On Success), returns FAILURE immediately - without even ticking the action - for every call within the next [code]decorator.seconds[/code].
func _decorator_cooldown(delta: float) -> Status:
	if _dec_cooldown_remaining != -1.0:
		_dec_cooldown_remaining -= delta
		if _dec_cooldown_remaining > 0.0:
			return Status.FAILURE
		_dec_cooldown_remaining = -1.0

	var status : Status = tick(delta)
	if status != Status.RUNNING:
		var mode : int = int(decorator.get("cooldown_mode", 0))
		if mode == 0 or (mode == 1 and status == Status.SUCCESS):
			_dec_cooldown_remaining = decorator.get("seconds", 0.0) as float

	return status

## Delay: [code]decorator.delay_mode[/code] 0 Before waits [code]decorator.seconds[/code] before ticking the action for the first time; 1 After ticks the action right away but, once it reports a non-RUNNING outcome, holds that outcome back for [code]decorator.seconds[/code] before actually returning it.
func _decorator_delay(delta: float) -> Status:
	var mode : int = int(decorator.get("delay_mode", 0))
	var secs : float = decorator.get("seconds", 0.0) as float

	if mode == 0: # Before
		if _dec_elapsed < secs:
			_dec_elapsed += delta
			return Status.RUNNING
		return tick(delta)

	# After
	if _dec_delayed_status != -1:
		_dec_elapsed += delta
		if _dec_elapsed < secs:
			return Status.RUNNING
		var held : Status = _dec_delayed_status as Status
		_dec_delayed_status = -1
		return held

	var status : Status = tick(delta)
	if status == Status.RUNNING:
		return status
	_dec_delayed_status = status
	_dec_elapsed = 0.0
	return Status.RUNNING

## Condition: reads the boolean [BlackboardVariable] bound to [code]decorator.blackboard_key[/code] (same drag-and-drop binding as a regular behavior property, restricted to [constant TYPE_BOOL]). Unbound passes through to [method tick] unmodified; bound and [code]false[/code] returns FAILURE without ticking the action; bound and [code]true[/code] ticks the action normally.
func _decorator_condition(delta: float) -> Status:
	var key : StringName = decorator.get("blackboard_key", &"") as StringName
	if key == &"":
		return tick(delta)

	var graph : BehaviorGraph = get_graph()
	if graph == null:
		return abort("decorator: lost graph reference while resolving condition '%s'" % key)

	var variable : BlackboardVariable = graph.get_blackboard_property(key)
	if variable == null or typeof(variable.value) != TYPE_BOOL:
		return abort("decorator: blackboard variable '%s' not found or not boolean" % key)

	if not bool(variable.value):
		return Status.FAILURE
	return tick(delta)

#endregion

@export_group("Properties")

## Initializes the node by calling every overridable [code]set_*[/code] method, in order: [br]
## -    [method set_node_category],[br]
## -    [method build_conditions] (which in turn calls [method set_conditions]), 
## -    [method set_instruction],
## -    [method set_input], 
## -    [method set_output],
## -    [method set_allows_multiple_outputs]. 
## Also triggers a first call to [method get_property_list] so that [member behavior_properties] gets populated via [method set_properties].
func _init() -> void:
	node_category = set_node_category()
	input = set_input()
	output=set_output()
	mute_enabled = set_mutable()
	breakpoint_enabled=set_breakpointable()
	build_conditions()
	instruction = set_instruction()
	allows_multiple_outputs = set_allows_multiple_outputs()

func _validate_property(property: Dictionary) -> void:
	if property["hint_string"].begins_with("BeGraph"):
		property["usage"]|=PROPERTY_USAGE_DEFAULT

## Override this function to set the node category. If the string returned matches one of the categories found in the Project Settings, then it will allow the node to have custom colors for background and border when selected
func set_node_category()->String:
	return "action_node"

## Override this function with a PackedStringArray. Each entry in the array will be a condition.[br]
## Variables can be used via with the [code]{}[/code] annotation.
func set_conditions() -> PackedStringArray :
	return PackedStringArray([])

## Used to build conditions starting from the array given by the [method set_conditions] method.[br]
## If one or more conditions are set, [param output] gets set to [code]false[/code]
func build_conditions() -> void :
	var conditions_texts : PackedStringArray = set_conditions()
	if conditions_texts.size() == 0: 
		return #return if there is no condition set
	
	output = false #output automatically set to false
	for condition_text in conditions_texts:
		var behavior_condition : Dictionary = {
			"text":condition_text,
			"next":null,
		}
		conditions.append(behavior_condition)

## Enables a blackboard reference in [param behavior_property][br]
## If this method gets called just with the [code]name[/code] parameter, without [code]blackboard[/code] or [code]blackboard_key[/code], the blackboard reference gets disabled
func set_node_property_blackboard_key(property: StringName, blackboard_key: StringName = &"") -> void:
	if blackboard_key == &"":
		_blackboard_bindings.erase(property)
	else:
		_blackboard_bindings[property] = blackboard_key
	blackboard_key_set.emit(property, blackboard_key)
	emit_changed()

func is_blackboard_reference_enabled_for_key(key: StringName) -> bool:
	return _blackboard_bindings.values().has(key)

func get_blackboard_key(property: StringName) -> StringName:
	return _blackboard_bindings.get(property, &"")
	
func _get(property: StringName) -> Variant:
	var key : StringName = _blackboard_bindings.get(property, &"")
	if key == &"":
		return null  # fallback to default get
	var graph : BehaviorGraph = get_graph()
	if graph == null:
		return null
	return graph.get_blackboard_property(key).value

func _set(property: StringName, value: Variant) -> bool:
	var key : StringName = _blackboard_bindings.get(property, &"")
	if key == &"":
		return false
	var graph : BehaviorGraph = get_graph()
	if graph != null:
		graph.set_blackboard_value(key, value)
		emit_changed()
	return true

func get_agent()->Node:
	var graph : BehaviorGraph = get_graph()
	if graph == null:
		push_error("Graph reference lost for node %s" % resource_name)
		return null
	
	var agent : BehaviorAgent = graph.get_agent_node()
	if agent == null:
		push_error("Agent not set for graph %s" % graph)
		return null
	return agent

func get_graph() -> BehaviorGraph:
	if _graph_ref == null:
		return null
	return _graph_ref.get_ref() as BehaviorGraph

## Returns the value stored under the given key (e.g. [code]"type"[/code], [code]"hint"[/code], [code]"blackboard_key"[/code]) if [param info] is provided. [br]
## Returns the full property [Dictionary] otherwise (or if [param info] is not a valid key (check [param behavior_properties] or [method_add_behavior_property])
func get_node_property_info(property: StringName, info: String = "") -> Variant:
	for prop in get_property_list():
		if prop["name"] != property: 
			continue
		if info == "":
			return prop
		return prop.get(info, null)
	push_error("Property '%s' not found" % property)
	return null

## Override to opt a node out of do_tick()'s automatic tick_next() call on SUCCESS.[br]
## Only needed by a node whose own tick() already decides on its own when/whether to call
## tick_next() and reports upward *the successor's real status* (rather than a fixed
## SUCCESS/FAILURE regardless of what's downstream) - see do_tick()'s doc for why mixing the
## two causes a double tick_next() call.
func _manual_successor_propagation() -> bool:
	return false

## Public entry point used to actually run this node: calls the concrete [method tick] implementation, then records [member last_status]/[member last_tick_time] and emits [signal ticked].[br]
## [method tick_next] and [method tick_condition] call this (instead of [method tick] directly) to reach a successor, and [BehaviorAgent] calls this on the graph's starting node - so every tick anywhere in the graph passes through here exactly once. This is what lets external tools (like the live graph debugger) track each node's status without any individual [BehaviorNode] subclass having to report it itself.
func do_tick(delta: float) -> Status:
	if breakpoint_enabled:
		breakpoint
	
	if mute_enabled:
		var muted_status : Status = tick_next(delta) if conditions.is_empty() else tick_condition(delta)
		last_status = muted_status
		last_tick_time = Time.get_ticks_msec()
		ticked.emit(muted_status)
		return muted_status
	
	# Node is not in RUNNING state during previous frame
	if last_status != Status.RUNNING:
		last_status = -1
		_connect_blackboard_signals()
		_reset_decorator_state()
		on_start()
		
		if last_status == Status.ERROR:
			last_tick_time = Time.get_ticks_msec()
			on_end(Status.ERROR)
			_disconnect_blackboard_signals()
			ticked.emit(Status.ERROR)
			return Status.ERROR

	var status: Status = _tick_with_decorator(delta)

	# Automatic forward propagation: fires tick_next() once, in the exact spot a node's own
	# tick() used to call it, for any node that (a) finished with SUCCESS, (b) has a single,
	# unconditional successor (no conditions, no multiple outputs), and (c) hasn't opted out
	# because it needs to report the successor's *real* status instead of a fixed one.
	if status == Status.SUCCESS and output and not allows_multiple_outputs and conditions.is_empty() and not _manual_successor_propagation():
		tick_next(delta)
	
	last_status = status
	last_tick_time = Time.get_ticks_msec()

	if status != Status.RUNNING: # Node just ended (SUCCESS or FAILURE)
		on_end(status) 
		_disconnect_blackboard_signals()

	ticked.emit(status)
	return status

## Routes [method tick] through [member decorator] (when this is an [code]action_node[/code] with a decorator set); returns the decorated [enum Status]. Called by [method do_tick] instead of [method tick] directly.
func _tick_with_decorator(delta: float) -> Status:
	if !supports_decorator():
		return tick(delta)

	match String(decorator.get("type", "none")):
		"inverter": return _decorator_inverter(delta)
		"force": return _decorator_force(delta)
		"repeater": return _decorator_repeater(delta)
		"time_limit": return _decorator_time_limit(delta)
		"cooldown": return _decorator_cooldown(delta)
		"delay": return _decorator_delay(delta)
		"condition": return _decorator_condition(delta)
		_: return tick(delta) # "none", or an unrecognized type

## Adds [param n] as a successor of this node. If [member output] is [code]true[/code] (no [member conditions] set), [param n] is appended to [member _next_ref] (unless already present); [param from_port] is unused in this case. Otherwise, [param n] becomes the successor of the condition at index [param from_port], replacing any previous one.
func add_next(n : BehaviorNode, from_port : int) -> void:
	if output:
		if _next_ref.has(n.resource_name):
			return
		if not allows_multiple_outputs:
			_next_ref.clear()
		_next_ref.append(n.resource_name)
		
	else:
		var current : StringName = conditions[from_port]["next"] if conditions[from_port]["next"] else &""
		if current == &"" or current != n.resource_name: 
			conditions[from_port]["next"] = n.resource_name

## Removes [param n] as a successor of this node (see [method add_next] for how successors are stored depending on [member output]/[member conditions]). Also prunes any dead (freed) weak references found along the way.
func remove_next(n : BehaviorNode, from_port : int) -> void:
	if output:
		_next_ref.erase(n.resource_name)
	else:
		var current : StringName = conditions[from_port]["next"]
		
		var cond_1 : bool = current != null
		var cond_2 : bool = current == n.resource_name or current== null
		if  cond_1 and cond_2: 
			conditions[from_port]["next"] = null

## Ticks the successor stored at [param index] inside [member _next_ref] and returns its [enum Status]. Routes through [method do_tick] (rather than calling [method tick] directly) so the successor's status/tick-time gets recorded.
func tick_next(delta:float,index:int = 0) -> Status:
	if index >= _next_ref.size():
		return Status.SUCCESS # Node has no successors, if it wants to tick a successor, but it has none, then it means it accomplished its purpose

	var target: StringName = _next_ref[index]
	var graph: BehaviorGraph = get_graph()
	if graph and graph.nodes.has(target):
		return graph.nodes[target].do_tick(delta)

	push_error("BehaviorNode %s: target node '%s' at index %d is invalid or missing" % [resource_name, target, index])
	return Status.FAILURE
	

## Ticks the successor bound to the condition at [param index] inside [member conditions] and returns its [enum Status]. Routes through [method do_tick] (rather than calling [method tick] directly) so the successor's status/tick-time gets recorded.
func tick_condition(delta:float,index:int = 0) -> Status:
	if index < conditions.size():
		var target : StringName = conditions[index]["next"] if conditions[index]["next"] else &""
		if target != &"": 
			return (_graph_ref.get_ref() as BehaviorGraph).nodes[target].do_tick(delta)
		return Status.FAILURE
	push_error("BehaviorNode %s has less than %s conditions" % [self, index+1])
	return Status.FAILURE
## Resolves a property value. If [code]resolve node[/code] is set to [code]true[/code] and the given property value is a nodepath, returnes the resolved nodepath via [method _resolve_node]. Returns the blackboard value if bound, otherwise returns the fallback local variable.
func eval(property_name: StringName,resolve_node:bool=false, fallback_value: Variant = null) -> Variant:
	if fallback_value == null:
		fallback_value = get(property_name)
		
	var key: StringName = _blackboard_bindings.get(property_name, &"")
	if key != &"":
		var graph: BehaviorGraph = get_graph()
		if graph != null:
			var value: Variant = graph.get_blackboard_value(key, fallback_value)
			return _resolve_node(value) if (resolve_node and value is NodePath) else value
	return fallback_value
## Accepts either an absolute or relative [NodePath] (resolved through the owning [BehaviorAgent]'s [member BehaviorAgent.actor]) or a direct reference to a [Node] (useful if [param value] is connected to a blackboard variable containing the node).
func _resolve_node(value: Variant) -> Node:
	if Engine.is_editor_hint():
		return null
	if value == null:
		push_error("BehaviorNode %s: trying to resolve null value" % resource_name)
		return null
	if value is NodePath and value != NodePath(""):
		var agent : Node = get_agent()
		if agent == null or agent.actor == null:
			push_error("BehaviorNode %s: missing agent or actor" % resource_name)
			return null
		var resolved = agent.actor.get_node_or_null(value)
		if resolved == null:
			push_error("BehaviorNode %s: node not found at path '%s'" % [resource_name, value])
		return resolved
	return value as Node



## Serializable form of node, for debug purposes.
func to_debug_info() -> Dictionary:
	var const_map : Dictionary = get_script().get_script_constant_map() if get_script() else {}
	return {
		"name": String(resource_name),
		"category": node_category,
		"display_name": const_map.get("DISPLAY_NAME", node_category),
		"input": input,
		"output": output,
		"position": position_in_graph,
		"conditions": conditions.map(func(c): return String(c["text"])),
		"instruction": instruction,
		"behavior_properties": serialize_properties(),
	}

## Current values of behavior properties.
func serialize_properties() -> Array:
	return get_behavior_property_list().map(func(p: Dictionary):
		var v : Variant = get(p["name"])
		var cond:bool = is_blackboard_reference_enabled_for_key(p["name"])
		var key : String = get_blackboard_key(p["name"]) if cond else ""
		return {
			"name": String(p["name"]),
			"type": p["type"],
			"value": v,
			"blackboard_key": key,
		}
	)

func has_behavior_properties()->bool:
	return not get_behavior_property_list().is_empty()

func get_behavior_property_list()->Array[Dictionary]:
	var ret : Array[Dictionary]
	for p in get_property_list():
		if p["hint_string"].begins_with("BeGraph"):
			ret.append(p)
	return ret

func _connect_blackboard_signals() -> void:
	var graph = get_graph()
	if graph and not graph.blackboard_value_changed.is_connected(_on_blackboard_value_changed):
		graph.blackboard_value_changed.connect(_on_blackboard_value_changed)

func _disconnect_blackboard_signals() -> void:
	var graph = get_graph()
	if graph and graph.blackboard_value_changed.is_connected(_on_blackboard_value_changed):
		graph.blackboard_value_changed.disconnect(_on_blackboard_value_changed)

func _on_blackboard_value_changed(key: StringName, _new_value: Variant) -> void:
	if is_blackboard_reference_enabled_for_key(key):
		on_blackboard_property_changed(key)

func on_blackboard_property_changed(key: StringName) -> void:
	pass

func supports_decorator() -> bool:
	return node_category != "access_point_node" and output and conditions.is_empty()
