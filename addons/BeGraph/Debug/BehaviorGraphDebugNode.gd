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
@onready var properties_toggle: Button = %PropertiesToggle

## Holds one row per behavior property (link icon, name, value). Re-appended as this node's last child once every condition row has been added, so it never shifts their slot indices; hidden until [member properties_toggle] is pressed.
@onready var properties_container: VBoxContainer = %PropertiesContainer

func _ready() -> void:
	properties_toggle.toggled.connect(func(pressed: bool): properties_container.visible = pressed)

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
	remove_child(properties_container)
	for cond_text in conditions:
		var cond_label := Label.new()
		cond_label.text = String(cond_text)
		cond_label.clip_text = true
		add_child(cond_label)
		set_slot_enabled_right(get_child_count() - 1, true)
	add_child(properties_container)

	var properties: Array = info.get("behavior_properties", [])
	properties_toggle.visible = not properties.is_empty()
	_build_properties(properties)

## Rebuilds [member properties_container] from scratch using [param properties] (an Array of [code]{"name","value","blackboard_key"}[/code] dictionaries).
func _build_properties(properties: Array) -> void:
	for child in properties_container.get_children():
		properties_container.remove_child(child)
		child.queue_free()
	for property in properties:
		_add_property_row(property)

## Appends one row for [param property] to [member properties_container]: a link icon (visible only when the property is bound to a blackboard entry), its name, and its current value.
func _add_property_row(property: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	properties_container.add_child(row)

	var linked: bool = String(property.get("blackboard_key", "")) != ""

	var link_icon := TextureRect.new()
	link_icon.custom_minimum_size = Vector2(16, 16)
	link_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	link_icon.texture = LINKED_ICON
	link_icon.modulate.a = 1.0 if linked else 0.0
	link_icon.tooltip_text = ("Linked to blackboard entry \"%s\"" % property["blackboard_key"]) if linked else "Fixed value"
	row.add_child(link_icon)

	var name_label := Label.new()
	name_label.text = String(property["name"])
	name_label.custom_minimum_size = Vector2(90, 0)
	name_label.clip_text = true
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = str(property.get("value"))
	value_label.clip_text = true
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if linked and ProjectSettings.has_setting("BeGraph/colors/allowed_variable_color_border"):
		value_label.add_theme_color_override("font_color", ProjectSettings.get_setting("BeGraph/colors/allowed_variable_color_border"))
	row.add_child(value_label)

## Sets [member status_label]'s text (color is handled separately by [BehaviorGraphDebugView], via this node's slot colors).
func update_status_text(text: String) -> void:
	status_label.text = text

## Refreshes only the displayed values (not the link icon/name) of an already-built properties list, in the same order [method setup] built them in. Used whenever fresher values come in (a node ticking, or a blackboard entry it reads from changing) without rebuilding the whole row set.
func update_property_values(properties: Array) -> void:
	var rows := properties_container.get_children()
	for i in min(rows.size(), properties.size()):
		var value_label: Label = rows[i].get_child(2)
		value_label.text = str(properties[i].get("value"))
