@tool
@abstract class_name BehaviorNode
extends Resource



##The abstract class every node written for the BeGraph plugin must extend.[br]
##In order to show a custom name, a node must define the [code]DISPLAY_NAME[/code] String constant.

##Return value for the [method tick] method.
enum Status{SUCCESS,FAILURE,RUNNING, ERROR = -1}

## Describes what the node does. Logic to determine which node is next in execution is written here.
@abstract func tick() -> Status

## The line displayed in the node. use [code]{}[/code] annotation to declare variables.
@abstract func set_instruction() -> String

## If set to [code]true[/code], allows this node to have a predecessor.
@abstract func set_input()->bool

## If set to [code]true[/code], allows this node to have a successor. [br]
## If conditions are set, this gets automatically set to false.
@abstract func set_output()->bool

##If set to [code]true[/code], allows this node to have multiple successors, while, if set to [code]false[/code], allows only for one successor.
@abstract func set_allows_multiple_outputs() -> bool

##Defines the variables that can be used inside a BehaviorNode's code.
@abstract func set_properties()-> void

## Instruction displayed in node. To set this parameter, use the [method set_instruction] method
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var instruction : String = ""

## A node's direct array of successors. If [param allows_multiple_outputs] is set to [code]true[/code], this node can have multiple successors, accessible using the classic array syntax
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var next : Array[BehaviorNode]

## Defines multiple successors for this node depending on the logic of the node itself. To set conditions, use the [method set_conditions] method, providing a [code]PackedStringArray[/code].[br]Conditions can have only one successor
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var conditions : Array[BehaviorCondition]

##Contains all of the [BehaviorProperty] for this node.
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var behavior_properties:Array[Dictionary]

## For display purposes only, this parameter defines a node's category. Set using [method set_node_category]
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var node_category : String = ""

##Regular expression used to get variables from the text
var regex :RegEx= RegEx.create_from_string(r"\{([^{}]+)\}")

##If true, lets the node have one or more predecessor(s)
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var input : bool = false

##If true, lets the node have one or more, depending on [param allows_multiple_outputs] successor(s)
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var output : bool = false

##If true, lets the node have more than one successor per output slot ([param next] is allowed to have a size greater than 0)
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE)var allows_multiple_outputs : bool = false

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE) var position_in_graph : Vector2

@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE) var is_starting_node : bool :
	get():
		if node_category == "access_point_node": 
			return true
		return false

signal behavior_property_changed(name:StringName,blackboard_key:StringName)


## Initializes the node by calling every overridable [code]set_*[/code] method,
## in order: [method set_node_category], [method build_conditions] (which in
## turn calls [method set_conditions]), [method set_instruction],
## [method set_input], [method set_output], and
## [method set_allows_multiple_outputs]. Also triggers a first call to
## [method get_property_list] so that [member behavior_properties] gets
## populated via [method set_properties].
func _init() -> void:
	node_category = set_node_category()
	input = set_input()
	output=set_output()
	conditions = build_conditions()
	instruction = set_instruction()
	allows_multiple_outputs = set_allows_multiple_outputs()
	set_properties()

## Overrides [method Object._get_property_list] to expose this node's custom
## variables (defined via [method set_properties]) to the editor inspector.
func _get_property_list() -> Array[Dictionary]:
	return behavior_properties

##Override this function to set the node category. If the string returned matches one of the categories found in the Project Settings, then it will allow the node wo have custom colors for background and border when selected
func set_node_category()->String:
	return "action_node"

## Override this function with a PackedStringArray. Each entry in the array will be a condition.[br]
##Variables with the [code]{}[/code] annotation can be used.
func set_conditions() -> PackedStringArray :
	return PackedStringArray([])

## Used to build conditions starting from the array given by the [method set_conditions] method.[br]
##If one or more conditions are set, [param output] gets set to [code]false[/code]
func build_conditions() -> Array[BehaviorCondition] :
	var conditions_texts : PackedStringArray = set_conditions()
	if conditions_texts.size() == 0: 
		return[] #return if there is no condition set
	
	output = false #output automatically set to false
	var ret : Array[BehaviorCondition] = []
	for condition_text in conditions_texts:
		var behavior_condition : BehaviorCondition = BehaviorCondition.new(condition_text)
		ret.append(behavior_condition)
	return ret

##Utility function to build a property to inject into [method set_properties].
func _add_behavior_property(
	name:String = "", 
	default_value : Variant = null,
	hint:int=PROPERTY_HINT_NONE, 
	hint_string:String="", 
	classname:String="", 
	usage:int=PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_STORAGE)->void:
	var entry : Dictionary={
		"name":name,
		"class_name":classname,
		"type":typeof(default_value),
		"hint":hint,
		"hint_string":hint_string,
		"usage":usage,
		"value":default_value,
		"blackboard":null,
		"blackboard_key":&""
	}
	behavior_properties.append(entry) #populates [param behavior_properties]
	return
## Overrides [method Object._get]: looks up [param property] among
## [member behavior_properties] and returns its current value, or
## [code]null[/code] if no matching property is found. This is what allows
## behavior properties to be read via plain [code]node.property_name[/code]
## syntax.
func _get(property: StringName) -> Variant:
	for prop in behavior_properties:
		if prop["name"]==property:
			return prop["value"] #gets value from behavior_property
	return null

## Overrides [method Object._set]: looks up [param property] among
## [member behavior_properties] and, if found, updates its value and emits
## [signal Resource.changed] with the property's name and current blackboard
## key. Returns [code]true[/code] if the property was found and set, or
## [code]false[/code] otherwise.
func _set(property: StringName, value: Variant) -> bool:
	for prop in behavior_properties:
		if prop["name"] == property:
			prop["value"] = value #handles setting a value for a behavior_property with the given key
			changed.emit(prop["name"],prop["blackboard_key"])
			return true
	return false

##Enables a blackboard reference in [param behavior_property][br]
##If this method gets called just with the [code]name[/code] parameter, without [code]blackboard[/code] or [code]blackboard_key[/code], the blackboard reference gets disabled
func set_blackboard_reference(name:String,blackboard : BehaviorGraphBlackboard=null, blackboard_key: StringName=&""):
	for property in behavior_properties:
		if property["name"] == name:
			property["blackboard"]=blackboard
			property["blackboard_key"]=blackboard_key
			changed.emit(property["name"],property["blackboard_key"])
			return
	push_error("unable to set property, %s name not found"%name)
	return

## Returns [code]true[/code] if the variable associated to the given [code]key[/code] properties a blackboard
func is_blackboard_property_enabled(key:StringName)->bool:
	for property in behavior_properties:
		if property["name"] == key:
			return property["blackboard"] != null and property["blackboard_key"] != &""
	return false

func print_node_info()->void:
	print("NODE: %s"%self)
	print("   Name: %s"%get_script().get_path())
	print("   Category: %s"%node_category)
	print("   Successor(s): %s"%str(next))
	print("\nINSTRUCTION")
	print("   Node instruction: \"%s\""%instruction)
	print("\nVARIABLES [%s]"%behavior_properties.size())
	for v in behavior_properties:
		print("   Variable %s"%v.name)
		print("      Value: %s"%v.value)
		print("      Blackboard connection: %s from %s"%[v.blackboard_key,v.blackboard])
	if conditions.size()>0:
		print("\nCONDITIONS")
		for condition in conditions:
			print("   Condition %s leads to %s"%[condition.text,condition.next])

func add_next(n : BehaviorNode)->void:
	next.append(n)
	return

##Checks if there is a property with the given name in [param behavior_properties]
func _has(property:StringName) -> bool:
	for prop in behavior_properties:
		if prop["name"] == property:
			return true
	return false

##A class to establish a condition's text and successor
class BehaviorCondition:
	##Text for a condition, can use [code]{}[/code] properties
	var text : String 
	##[BehaviorNode] to be triggered after this condition
	var next : BehaviorNode 
	
	## Creates a new condition with the given display [param text] and,
	## optionally, its [param next] successor node.
	func _init(text:String= "", next:BehaviorNode = null) -> void:
		self.text = text
		self.next = next
