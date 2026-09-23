@tool
## Populates the info panel with everything about the currently selected [BehaviorNode]: its instruction, an extended description read from [member BehaviorNode.info], its input/output/ multiple-outputs flags, its conditions (with their linked successor, if any), and one inline editor per behavior property. Each property editor is an actual [BehaviorGraphNodeVariableEditor] — the same control used inside the graph nodes — so editing here updates the node exactly like editing on the graph, and blackboard variables can be dragged onto it the same way.[br] The visual layout/style lives entirely in [code]BehaviorNodeInfoPanel.tscn[/code] (unique-named nodes); this script only reads those references and writes data into them.
class_name BehaviorNodeInfoPanel
extends PanelContainer

## Scene reused for each property row's inline editor (same one [BehaviorGraphNode] uses).
const BEHAVIOR_GRAPH_NODE_VARIABLE = preload("uid://bup4fdlymdgmo")

## Color applied to secondary/placeholder text generated at runtime (rows the scene can't pre-style because their content doesn't exist yet).
var muted_color: Color = Color(0.498, 0.498, 0.498)

var flag_positive_color: Color = Color(0.0, 0.302, 0.145, 1.0)
var flag_negative_color: Color = Color(0.545, 0.0, 0.11, 1.0)

## Text shown when nothing is selected.
var no_node_text: String = "No node selected."
## Suffix shown on a condition row whose successor slot isn't connected.
var not_connected_text: String = "(not connected)"

@onready var empty_label: Label = %EmptyLabel
@onready var scroll: ScrollContainer = %ScrollContainer
@onready var content: VBoxContainer = %Content
@onready var instruction_caption_container: HBoxContainer = %InstructionCaptionContainer
@onready var instruction_label: RichTextLabel = %InstructionLabel
@onready var info_caption_container: HBoxContainer = %InfoCaptionContainer
@onready var info_label: RichTextLabel = %InfoLabel
@onready var flags_caption_container: HBoxContainer = %FlagsCaptionContainer
@onready var flags_container: HBoxContainer = %FlagsContainer
@onready var conditions_caption_container: HBoxContainer = %ConditionsCaptionContainer
@onready var conditions_container: VBoxContainer = %ConditionsContainer
@onready var properties_caption_container: HBoxContainer = %PropertiesCaptionContainer
@onready var properties_container: VBoxContainer = %PropertiesContainer

@onready var title_bar_color: ColorRect = %TitleBarColor
@onready var title_label: Label = %TitleLabel
@onready var category_label: Label = %CategoryLabel

@onready var input_label: Label = %InputLabel
@onready var output_label: Label = %OutputLabel
@onready var multiple_outputs_label: Label = %MultipleOutputsLabel

## Blackboard of the currently loaded graph, forwarded to every property editor.
var _blackboard: Array[BlackboardVariable] = []
## The [BehaviorNode] currently displayed, kept only to manage the [signal BehaviorNode.conditions_changed] connection.
var _current_node: BehaviorNode = null

func _ready() -> void:
	clear()

## Displays [param node]'s instruction, info text, flags, conditions and behavior properties, binding each property's inline editor to [param blackboard]. Pass [code]null[/code] to clear (see [method clear]).
func show_node(node: BehaviorNode, blackboard: Array[BlackboardVariable]) -> void:
	_blackboard = blackboard
	_disconnect_current_node()

	if node == null:
		clear()
		return

	_current_node = node
	if not node.conditions_changed.is_connected(_on_conditions_changed):
		node.conditions_changed.connect(_on_conditions_changed)

	empty_label.hide()
	scroll.show()
	
	var const_map = node.get_script().get_script_constant_map()
	title_label.text = "%s (%s)"%[const_map["DISPLAY_NAME"],node.resource_name] if const_map.has("DISPLAY_NAME") else node.resource_name
	
	var color_str : String = "BeGraph/colors/node_colors/%s/border_color" % node.node_category
	title_bar_color.color= ProjectSettings.get_setting(color_str)
	
	category_label.text = node.node_category
	
	var has_instruction : bool = node.instruction !=""
	instruction_caption_container.visible = has_instruction
	instruction_label.visible = has_instruction
	if has_instruction:
		instruction_label.text = node.instruction
		instruction_label.reset_size.call_deferred()
	
	var has_display_info : bool = const_map.has("DISPLAY_INFO")
	info_caption_container.visible = has_display_info
	info_label.visible = has_display_info
	if has_display_info:
		info_label.text = const_map["DISPLAY_INFO"]


	_build_flags(node)
	
	_clear_properties()
	var has_properties : bool = !node.behavior_properties.is_empty()
	properties_caption_container.visible = has_properties
	properties_container.visible = has_properties
	for property in node.behavior_properties:
		_add_property_row(node, property)

	_refresh_conditions()

## Resets the panel to its "nothing selected" state.
func clear() -> void:
	_disconnect_current_node()
	_clear_properties()
	_clear_conditions()
	instruction_label.text = ""
	title_label.text = ""
	category_label.text=""
	info_label.text = ""
	info_label.remove_theme_color_override("font_color")
	scroll.hide()
	empty_label.text = no_node_text
	empty_label.show()

## Disconnects [member _current_node]'s [signal BehaviorNode.conditions_changed], if connected.
func _disconnect_current_node() -> void:
	if _current_node and _current_node.conditions_changed.is_connected(_on_conditions_changed):
		_current_node.conditions_changed.disconnect(_on_conditions_changed)
	_current_node = null

## Builds the "Input / Output / Allows multiple outputs" summary text for [param node].
func _build_flags(node: BehaviorNode) -> void:
	var input_color = flag_positive_color if node.input else flag_negative_color
	var output_color = flag_positive_color if node.output else flag_negative_color
	var multiple_output_color = flag_positive_color if node.allows_multiple_outputs else flag_negative_color
	
	input_label.set_indexed("theme_override_styles/normal:bg_color",input_color)
	output_label.set_indexed("theme_override_styles/normal:bg_color",output_color)
	multiple_outputs_label.set_indexed("theme_override_styles/normal:bg_color",multiple_output_color)

## Callback for [signal BehaviorNode.conditions_changed] on [member _current_node]: rebuilds the conditions section (its size/content may have changed, e.g. after editing an enum property).
func _on_conditions_changed() -> void:
	_refresh_conditions()

## Rebuilds [member _conditions_container] from [member _current_node]'s [member BehaviorNode.conditions].
func _refresh_conditions() -> void:
	_clear_conditions()
	if _current_node == null:
		return
	
	conditions_caption_container.visible = !_current_node.conditions.is_empty()
	conditions_container.visible = !_current_node.conditions.is_empty()

	for condition in _current_node.conditions:
		_add_condition_row(condition)

## Appends one row for [param condition] (its raw text plus the name of the node it's linked to, or a placeholder if unlinked) to [member _conditions_container].
func _add_condition_row(condition: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	conditions_container.add_child(row)

	var text_label := Label.new()
	text_label.text = String(condition["text"])
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(text_label)

	var next: StringName = condition["next"] if condition["next"] else &""
	var next_label := Label.new()
	next_label.text = "-> %s" % next if next != &"" else not_connected_text
	if next == &"":
		next_label.add_theme_color_override("font_color", muted_color)
	row.add_child(next_label)

## Removes every row from [member _conditions_container].
func _clear_conditions() -> void:
	for child in conditions_container.get_children():
		conditions_container.remove_child(child)
		child.queue_free()

## Appends one row (property name + inline [BehaviorGraphNodeVariableEditor]) for [param property], belonging to [param node], to [member _properties_container].
func _add_property_row(node: BehaviorNode, property: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	properties_container.add_child(row)
	

	var name_label := Label.new()
	name_label.text = String(property["name"])
	name_label.custom_minimum_size = Vector2(110, 0)
	name_label.clip_text = true
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_stretch_ratio=1
	row.add_child(name_label)

	var editor: BehaviorGraphNodeVariableEditor = BEHAVIOR_GRAPH_NODE_VARIABLE.instantiate()
	row.add_child(editor)
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor.size_flags_stretch_ratio=2

	if not editor.setup_variable_editor(node, property, _blackboard):
		push_warning("No available editor for \"%s\"" % property["name"])
		editor.queue_free()
		var fallback := Label.new()
		fallback.text = "{%s}" % property["name"]
		row.add_child(fallback)
	editor.var_property_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

## Removes every row from [member _properties_container].
func _clear_properties() -> void:
	for child in properties_container.get_children():
		properties_container.remove_child(child)
		child.queue_free()
