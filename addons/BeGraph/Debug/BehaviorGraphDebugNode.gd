@tool
## Visual [GraphNode] used by [BehaviorGraphDebugView] to render one [BehaviorNode]'s live debugging state.[br]
## Unlike the rest of [BehaviorGraphDebugView] (which builds its [GraphNode]s entirely in code, since it also has to run outside the editor for the in-game debug overlay), this node is defined in its own scene ([code]BehaviorGraphDebugNode.tscn[/code]) so its look can be tweaked directly in the editor; only the parts that depend on how many conditions/properties a node has (condition rows, property rows) are still built at runtime, from the [param info] dictionary passed to [method setup].[br]
## Shows the node's category/status (as before) plus its instruction text and, toggled via [member properties_toggle], a read-only list of its behavior properties - each row showing its current value and, via a link icon, whether that value is fixed or comes from the graph's blackboard.
class_name BehaviorGraphDebugNode
extends GraphNode

## Icon shown on a property row when its value is bound to a blackboard entry (reuses the same icon [BehaviorGraphNodeVariableEditor] uses for its link button).
const LINKED_ICON: Texture2D = preload("res://addons/BeGraph/Icons/link_icon.svg")

## Row containing [member subtitle_label] and [member instruction_label]. Occupies slot row 0, alongside this node's input/output slot - kept as a single child so condition rows (added dynamically in [method setup]) keep starting at row 2, matching [BehaviorGraphEdit]'s port numbering.
@onready var main_row: VBoxContainer = %MainRow
## Category/display name text.
@onready var subtitle_label: Label = %Subtitle
## The node's raw instruction text (with [code]{placeholder}[/code] tokens as authored, not resolved).
@onready var instruction_label: Label = %InstructionLabel

## Row containing [member status_label] and [member properties_toggle]. Occupies slot row 1, for the same reason as [member main_row].
@onready var status_row: HBoxContainer = %StatusRow
## Live status text ("idle"/"SUCCESS"/"FAILURE"/"RUNNING"), refreshed by [BehaviorGraphDebugView].
@onready var status_label: Label = %StatusLabel
## Shows/hides [member properties_container]. Hidden entirely when the node has no behavior properties.
@onready var properties_toggle: Button
@onready var properties_tree: Tree = %PropertiesTree

func _ready() -> void:
	properties_toggle = Button.new()
	properties_toggle.toggle_mode=true
	properties_toggle.flat=true
	properties_toggle.icon=load("res://addons/BeGraph/Icons/info_icon.svg")
	get_titlebar_hbox().add_child(properties_toggle)
	properties_toggle.toggled.connect(func(pressed: bool): 
		properties_tree.visible = pressed
		reset_size.call_deferred()
		)
	

## Configures every part of this node from [param info] (the same dictionary shape built by [method BehaviorGraphDebugView._info_from_node] / sent by [method BehaviorGraphDebugBridge._send_graph_structure]): title, subtitle, instruction, input/output/condition slots, and the (initially hidden) properties list.
func setup(info: Dictionary) -> void:
	name = info["name"]
	title = info["name"]
	subtitle_label.text = info.get("display_name", info.get("category", ""))

	var instruction: String = info.get("instruction", "")
	instruction_label.visible = instruction != ""
	instruction_label.text = instruction

	set_slot_enabled_left(0, info.get("input", false))
	var conditions: Array = info.get("conditions", [])
	set_slot_enabled_right(0, info.get("output", false) and conditions.is_empty())

	# Conditions must be added directly after row 1 (status_row) - pull properties_container
	# out first so it doesn't shift their slot indices, then re-append it last.
	remove_child(properties_tree)
	for cond_text in conditions:
		var cond_label := Label.new()
		cond_label.text = String(cond_text)
		cond_label.clip_text = true
		add_child(cond_label)
		set_slot_enabled_right(get_child_count() - 1, true)
	add_child(properties_tree)

	var properties: Array = info.get("behavior_properties", [])
	properties_toggle.visible = not properties.is_empty()
	_build_properties(properties)
	
## Rebuilds [member properties_container] from scratch using [param properties] (an Array of [code]{"name","value","blackboard_key"}[/code] dictionaries).
func _build_properties(properties: Array) -> void:
	properties_tree.clear()
	properties_tree.column_titles_visible = true
	properties_tree.set_column_title(0, "Key")
	properties_tree.set_column_title(1, "Value")
	properties_tree.set_column_expand(0, true)
	properties_tree.set_column_expand(1, true)
	properties_tree.set_column_expand_ratio(0,1)
	properties_tree.set_column_expand_ratio(1,3)
	properties_tree.set_column_custom_minimum_width(0, 28)
	properties_tree.create_item()
	properties_tree.hide()
	for property in properties:
		_add_property_row(property)
	
## Appends one row for [param property] to [member properties_container]: a link icon (visible only when the property is bound to a blackboard entry), its name, and its current value.
func _add_property_row(property: Dictionary) -> void:
	var linked: bool = String(property.get("blackboard_key", "")) != ""
	var item : TreeItem = properties_tree.create_item(properties_tree.get_root())
	item.set_text(0,property["name"])
	print(property["name"])
	item.set_icon(0, EditorInterface.get_editor_theme().get_icon(type_string(property["type"]), "EditorIcons"))
	
	if !linked:
		item.set_text(1,str(property.get("value")))
	else:
		item.set_text(1,property["blackboard_key"])
		item.set_icon(1,load("res://addons/BeGraph/Icons/link_icon.svg"))
	reset_size.call_deferred()

## Sets [member status_label]'s text (color is handled separately by [BehaviorGraphDebugView], via this node's slot colors).
func update_status_text(text: String) -> void:
	status_label.text = text

## Refreshes only the displayed values (not the link icon/name) of an already-built properties list, in the same order [method setup] built them in. Used whenever fresher values come in (a node ticking, or a blackboard entry it reads from changing) without rebuilding the whole row set.
func update_property_values(properties: Array) -> void:
	var item = properties_tree.get_root()
	for i in min(properties_tree.get_child_count(), properties.size()):
		if item == null:
			continue
		if String(properties[i].get("blackboard_key", "")) != "":
			item.set_text(1,properties[i]["blackboard_key"])
			item.set_icon(1,load("res://addons/BeGraph/Icons/link_icon.svg"))
		else:
			item.set_text(1,str(properties[i].get("value")))
		item = item.get_next()

			
