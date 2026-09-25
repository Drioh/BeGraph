@tool
@abstract class_name BehaviorNode
extends Resource

## The abstract class every node written for the BeGraph plugin must extend.[br]
##To show a custom name and icon, a node must define the [code]DISPLAY_NAME[/code] and the the [code]DISPLAY_ICON[/code] String constants.[br]

## Return value for the [method tick] method.
enum Status{SUCCESS,FAILURE,RUNNING}

## Property usage flags shared by every internal/read-only field of this resource (storage + read-only + editor visible, but not user-editable).
const INTERNAL_USAGE := PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR

## Describes what the node does. Logic to determine which node is next in execution is written here.[br]
## Never call this directly from outside the node: successors are ticked through [method tick_next]/[method tick_condition] (or, for the graph's starting node, by [BehaviorAgent]), which route through [method do_tick] instead so its execution can be tracked (e.g. by the live graph debugger).
@abstract func tick(delta) -> Status

## The line displayed in the node. use [code]{}[/code] annotation to declare variables.
@abstract func set_instruction() -> String

## If set to [code]true[/code], allows this node to have a predecessor.
@abstract func set_input()->bool

## If set to [code]true[/code], allows this node to have a successor. [br]
## If conditions are set, this gets automatically set to [code]false[/code].
@abstract func set_output()->bool

## If set to [code]true[/code], allows this node to have multiple successors, while, if set to [code]false[/code], allows only for one successor.
@abstract func set_allows_multiple_outputs() -> bool

## Defines the variables that can be used inside a BehaviorNode's code.[br]
## Must be populated using [method _add_behavior_property][br]
## Example:[br][codeblock]
##func set_properties()-> void:
##    _add_behavior_property("value_1",int(0))
##    _add_behavior_property("value_2",int(0))
##[/codeblock]
@abstract func set_properties()-> void

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

## Contains all of the behavior properties for this node. Has a custom definition of a property, different than the one returned by the [method get_property_list] method:[br]
##[codeblock]
##var entry : Dictionary={
##    "name":StringName # a normal script variable uses String,
##    "class_name":StringName,
##    "type": int        # typeof(default_value),
##    "hint": String,
##    "hint_string": String,
##    "custom_info": String,
##    "usage": BitMap,
##    "value": Variant,
##    "blackboard_key": StringName
##}
##[/codeblock]
@export_custom(PROPERTY_HINT_NONE, "", INTERNAL_USAGE)var behavior_properties:Array[Dictionary]

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

var dirty : bool = true
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
	build_conditions()
	instruction = set_instruction()
	allows_multiple_outputs = set_allows_multiple_outputs()
	set_properties()

## Overrides [method Object._get_property_list] to expose this node's custom variables (defined via [method set_properties]) to the editor inspector.
func _get_property_list() -> Array[Dictionary]:
	return behavior_properties

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

## Utility function to build a property to inject into [method set_properties].[br]
## Uses a custom property definition, different than the one returned by [method get_property_list]:
##[codeblock]
##var entry : Dictionary={
##    "name":StringName # a normal script variable uses String,
##    "class_name":StringName,
##    "type": int        # typeof(default_value),
##    "hint": String,
##    "hint_string": String,
##    "custom_info": String,
##    "usage": BitMap,
##    "value": Variant,
##    "blackboard_key": StringName
##}
##[/codeblock]
func _add_behavior_property(
	name:StringName = &"", 
	default_value : Variant = null,
	hint:int=PROPERTY_HINT_NONE, 
	hint_string:Variant="",
	custom_info:String="",
	classname:String="", 
	usage:int=PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_STORAGE)->void:

	var entry : Dictionary={
		"name":name,
		"class_name":classname,
		"type":typeof(default_value),
		"hint":hint,
		"hint_string":str(hint_string) if not hint_string is not Callable else hint_string,
		"custom_info":custom_info,
		"usage":usage|PROPERTY_USAGE_SCRIPT_VARIABLE|PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_STORAGE,
		"value":default_value,
		"blackboard_key":&""
	}
	behavior_properties.append(entry) #populates [param behavior_properties]
	return

## Overrides [method Object._set]: looks up [param property] among [member behavior_properties] and, if found, updates its value and emits [signal Resource.changed] with the property's name and current blackboard key. Returns [code]true[/code] if the property was found and set, or [code]false[/code] otherwise.
func _set(property: StringName, value: Variant) -> bool:
	for prop in behavior_properties:
		if prop["name"] != property:
			continue
		
		var old_value:Variant = prop["value"]
		prop["value"] = value
		
		if prop["usage"] & PROPERTY_USAGE_NIL_IS_VARIANT:
			# lets a property originally defined as null to mantain its possiiblity to havemultiple value types
			prop["type"] = typeof(null)
		
		if prop["type"]==TYPE_PACKED_STRING_ARRAY and prop["custom_info"]=="conditions":
			# property is both a PackedStringArray and is defined as a condition
			var previous_size:int = old_value.size()
			if previous_size==0:
				# if the array gets a 0 size, it gets populated with a single value "Value 0"
				prop["value"] = PackedStringArray(["Value 0"])
			
			if previous_size<value.size():
				# if the action performed is a new entry creation, initializes it to "new enumvalue"
				prop["value"][-1]="new enum value"
			
			var values = prop["value"]
			for p in behavior_properties:
				if p["custom_info"] != prop["name"]: 
					continue
				#when changing values, the PackedStringArray populates its "selector"'spossible values
				p["hint_string"] = ",".join(values)
				if int(p["value"]) >= values.size(): 
					p["value"] = 0
			
			var old_conditions : Array[Dictionary] = conditions.duplicate(true)
			conditions.clear()
			for i in values.size():
				var cond : bool = i < old_conditions.size()
				var kept_next : WeakRef = old_conditions[i]["next"] if cond else null
				conditions.append({"text": values[i], "next": kept_next})
				
			output = false
			conditions_changed.emit()
			
			# an element gets added or removed, so that previous size is both valid anddifferent than the old value
			var cond_1 : bool = previous_size != -1 and previous_size != values.size()
			# happens specifically when value gets set via the enter button when editing anentry
			var cond_2 : bool = old_value==prop["value"]
			if cond_1 or cond_2: 
				notify_property_list_changed.call_deferred()
				
		changed.emit()
		return true
	return false

## Enables a blackboard reference in [param behavior_property][br]
## If this method gets called just with the [code]name[/code] parameter, without [code]blackboard[/code] or [code]blackboard_key[/code], the blackboard reference gets disabled
func set_node_property_blackboard_key(property:String, blackboard_key: StringName=&""):
	for prop in behavior_properties:
		if prop["name"] != property: 
			continue
		prop["blackboard_key"]=blackboard_key
		blackboard_key_set.emit(property,blackboard_key)
		return
	push_error("unable to set property, %s name not found"%property)
	return
	
## Overrides [method Object._get]: looks up [param property] among [member behavior_properties] and returns its current value, or [code]null[/code] if no matching property is found. This is what allows behavior properties to be read via plain [code]node.property_name[/code] syntax.
func _get(property: StringName) -> Variant:
	for prop in behavior_properties:
		if prop["name"]!=property: 
			continue
		var key : StringName = prop["blackboard_key"]
		
		if key == &"": 
			return prop["value"] #gets value from behavior_property
		
		var graph : BehaviorGraph = _graph_ref.get_ref()
		if graph:
			return graph.get_blackboard_property(key).value
	return null

## Returns the value stored under the given key (e.g. [code]"type"[/code], [code]"hint"[/code], [code]"blackboard_key"[/code]) if [param info] is provided. [br]
## Returns the full property [Dictionary] otherwise (or if [param info] is not a valid key (check [param behavior_properties] or [method_add_behavior_property])
func get_node_property_info(property:StringName,info:String="") -> Variant:
	for prop in behavior_properties:
		if prop["name"]!=property: 
			continue
		if info == "" or !prop[info]: 
			return prop
		
		return prop[info]
	push_error("property '%s' not found"%property)
	return 

func get_agent()->Node:
	var graph : BehaviorGraph = _graph_ref.get_ref()
	if graph == null:
		push_error("Graph reference lost for node %s" % resource_name)
		return null
	var agent : Node = graph.get_agent_node()
	if agent == null:
		push_error("Agent not set for graph %s" % graph)
		return null
	return agent


## Checks if there is a property with the given name in [param behavior_properties]
func _has(property:StringName) -> bool:
	for prop in behavior_properties:
		if prop["name"] == property: 
			return true
	return false

## Returns [code]true[/code] if the variable associated to the given [code]key[/code] properties a blackboard
func is_blackboard_reference_enabled(key:StringName)->bool:
	for property in behavior_properties:
		if property["name"] == key: 
			return property["blackboard_key"] != &""
	return false

## Public entry point used to actually run this node: calls the concrete [method tick] implementation, then records [member last_status]/[member last_tick_time] and emits [signal ticked].[br]
## [method tick_next] and [method tick_condition] call this (instead of [method tick] directly) to reach a successor, and [BehaviorAgent] calls this on the graph's starting node - so every tick anywhere in the graph passes through here exactly once. This is what lets external tools (like the live graph debugger) track each node's status without any individual [BehaviorNode] subclass having to report it itself.
func do_tick(delta:float) -> Status:
	var status : Status = tick(delta)
	last_status = status
	last_tick_time = Time.get_ticks_msec()
	ticked.emit(status)
	return status

## Adds [param n] as a successor of this node. If [member output] is [code]true[/code] (no [member conditions] set), [param n] is appended to [member _next_ref] (unless already present); [param from_port] is unused in this case. Otherwise, [param n] becomes the successor of the condition at index [param from_port], replacing any previous one.
func add_next(n : BehaviorNode, from_port : int) -> void:
	if output:
		if not _next_ref.has(n.resource_name):
			if not allows_multiple_outputs:
				_next_ref[0] = n.resource_name
				return
			_next_ref.append(n.resource_name)
		return
	else:
		var current : StringName = conditions[from_port]["next"] if conditions[from_port]["next"] else &""
		if current == &"" or current != n.resource_name: 
			conditions[from_port]["next"] = n.resource_name
		return

## Removes [param n] as a successor of this node (see [method add_next] for how successors are stored depending on [member output]/[member conditions]). Also prunes any dead (freed) weak references found along the way.
func remove_next(n : BehaviorNode, from_port : int) -> void:
	if output:
		_next_ref.erase(n.resource_name)
		return
	else:
		var current : StringName = conditions[from_port]["next"]
		
		var cond_1 : bool = current != null
		var cond_2 : bool = current == n.resource_name or current== null
		if  cond_1 and cond_2: 
			conditions[from_port]["next"] = null
		return

## Ticks the successor stored at [param index] inside [member _next_ref] and returns its [enum Status]. Routes through [method do_tick] (rather than calling [method tick] directly) so the successor's status/tick-time gets recorded.
func tick_next(delta:float,index:int = 0) -> Status:
	if index < _next_ref.size():
		var target = _next_ref[index] if _next_ref[index] else &""
		if target != &"": 
			return (_graph_ref.get_ref() as BehaviorGraph).nodes[target].do_tick(delta)
		push_error("BehaviorNode %s: successor at index %s was freed" % [self, index])
		return Status.FAILURE
	return Status.SUCCESS # Node has no successors, if it wants to tick a successor, but it has none, then it means it accomplished its purpose

## Ticks the successor bound to the condition at [param index] inside [member conditions] and returns its [enum Status]. Routes through [method do_tick] (rather than calling [method tick] directly) so the successor's status/tick-time gets recorded.
func tick_condition(delta:float,index:int = 0) -> Status:
	if index < conditions.size():
		var target : StringName = conditions[index]["next"] if conditions[index]["next"] else &""
		if target != &"": 
			return (_graph_ref.get_ref() as BehaviorGraph).nodes[target].do_tick(delta)
		return Status.FAILURE
	push_error("BehaviorNode %s has less than %s conditions" % [self, index+1])
	return Status.FAILURE

## Accepts either an absolute or relative [NodePath] (resolved through the owning [BehaviorAgent]'s [member BehaviorAgent.actor]) or a direct reference to a [Node] (useful if [param value] is connected to a blackboard variable containing the node).
func _resolve_node(value: Variant) -> Node:
	if not Engine.is_editor_hint():
		if value is Node2D or value is Node3D:
			return value
		if value is NodePath and value != NodePath(""):
			var agent : Node = get_agent()
			if agent == null or agent.owner == null:
				push_error("BehaviorNode %s: cannot resolve scene root for %s" % [resource_name, value])
				return null
			return agent.actor.get_node(value)
	return null
