@tool
## Populates the info panel with everything about the currently selected [BehaviorNode]: its
## instruction, an extended description read from [member BehaviorNode.info], its input/output/
## multiple-outputs flags, its conditions (with their linked successor, if any), and one inline
## editor per behavior property. Each property editor is an actual [BehaviorGraphNodeVariableEditor]
## — the same control used inside the graph nodes — so editing here updates the node exactly like
## editing on the graph, and blackboard variables can be dragged onto it the same way.
class_name BehaviorNodeInfoPanel
extends PanelContainer

## Scene reused for each property row's inline editor (same one [BehaviorGraphNode] uses).
const BEHAVIOR_GRAPH_NODE_VARIABLE = preload("uid://bup4fdlymdgmo")

var _scroll: ScrollContainer
var _content: VBoxContainer
var _empty_label: Label
var _instruction_label: Label
var _info_label: Label
var _flags_label: Label
var _properties_container: VBoxContainer
var _conditions_container: VBoxContainer

## Blackboard of the currently loaded graph, forwarded to every property editor.
var _blackboard: Array[BlackboardVariable] = []
## The [BehaviorNode] currently displayed, kept only to manage the [signal BehaviorNode.conditions_changed] connection.
var _current_node: BehaviorNode = null

func _ready() -> void:
	_build_ui()
	clear()

## Builds the panel's fixed layout once: an "empty" placeholder plus a scrollable column with the
## instruction, the info text, the flags, the conditions, and the properties list.
func _build_ui() -> void:
	_empty_label = Label.new()
	_empty_label.text = "No node selected."
	add_child(_empty_label)

	_scroll = ScrollContainer.new()
	add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	_scroll.add_child(_content)

	_instruction_label = _add_section("INSTRUCTION")
	_info_label = _add_section("INFO")
	_flags_label = _add_section("FLAGS")

	_add_caption("CONDITIONS")
	_conditions_container = VBoxContainer.new()
	_conditions_container.add_theme_constant_override("separation", 2)
	_content.add_child(_conditions_container)

	_add_caption("PROPERTIES")
	_properties_container = VBoxContainer.new()
	_properties_container.add_theme_constant_override("separation", 4)
	_properties_container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_content.add_child(_properties_container)

## Adds a small caption row (used for section titles) to [member _content].
func _add_caption(text: String) -> void:
	var caption := Label.new()
	caption.text = text
	caption.add_theme_color_override("font_color", Color(0.498, 0.498, 0.498))
	_content.add_child(caption)

## Adds a captioned, word-wrapped section to [member _content] and returns its content [Label].
func _add_section(title: String) -> Label:
	_add_caption(title)
	var content_label := Label.new()
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(content_label)
	return content_label

## Displays [param node]'s instruction, info text, flags, conditions and behavior properties,
## binding each property's inline editor to [param blackboard]. Pass [code]null[/code] to clear
## (see [method clear]).
func show_node(node: BehaviorNode, blackboard: Array[BlackboardVariable]) -> void:
	_blackboard = blackboard
	_disconnect_current_node()

	if node == null:
		clear()
		return

	_current_node = node
	if not node.conditions_changed.is_connected(_on_conditions_changed):
		node.conditions_changed.connect(_on_conditions_changed)

	_empty_label.hide()
	_scroll.show()
	_instruction_label.text = "    %s"%node.instruction
	_info_label.text = "    %s"%node.info if not node.info.is_empty() else "    (no description provided)"
	if node.info.is_empty():
		_info_label.add_theme_color_override("font_color", Color(0.498, 0.498, 0.498))
	_flags_label.text = _build_flags_text(node)

	_clear_properties()
	for property in node.behavior_properties:
		_add_property_row(node, property)

	_refresh_conditions()

## Resets the panel to its "nothing selected" state.
func clear() -> void:
	_disconnect_current_node()
	_clear_properties()
	_clear_conditions()
	_instruction_label.text = ""
	_info_label.text = ""
	_flags_label.text = ""
	_scroll.hide()
	_empty_label.show()

## Disconnects [member _current_node]'s [signal BehaviorNode.conditions_changed], if connected.
func _disconnect_current_node() -> void:
	if _current_node and _current_node.conditions_changed.is_connected(_on_conditions_changed):
		_current_node.conditions_changed.disconnect(_on_conditions_changed)
	_current_node = null

## Builds the "Input / Output / Allows multiple outputs" summary text for [param node].
func _build_flags_text(node: BehaviorNode) -> String:
	return "    Input: %s\n    Output: %s\n    Allows multiple outputs: %s" % [
		"🟢" if node.input else "🔴",
		"🟢" if node.output else "🔴",
		"🟢" if node.allows_multiple_outputs else "🔴"
	]

## Callback for [signal BehaviorNode.conditions_changed] on [member _current_node]: rebuilds the
## conditions section (its size/content may have changed, e.g. after editing an enum property).
func _on_conditions_changed() -> void:
	_refresh_conditions()

## Rebuilds [member _conditions_container] from [member _current_node]'s [member BehaviorNode.conditions].
func _refresh_conditions() -> void:
	_clear_conditions()
	if _current_node == null:
		return
	if _current_node.conditions.is_empty():
		var none_label := Label.new()
		none_label.text = "    (no conditions)"
		none_label.add_theme_color_override("font_color", Color(0.498, 0.498, 0.498))
		_conditions_container.add_child(none_label)
		return
	for condition in _current_node.conditions:
		_add_condition_row(condition)

## Appends one row for [param condition] (its raw text plus the name of the node it's linked to,
## or a placeholder if unlinked) to [member _conditions_container].
func _add_condition_row(condition: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_conditions_container.add_child(row)

	var text_label := Label.new()
	text_label.text = "    %s"%String(condition["text"])
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(text_label)

	var next: StringName = condition["next"] if condition["next"] else &""
	var next_label := Label.new()
	next_label.text = "-> %s" % next if next != &"" else "(not connected)"
	if next == &"":
		next_label.add_theme_color_override("font_color", Color(0.498, 0.498, 0.498))
	row.add_child(next_label)

## Removes every row from [member _conditions_container].
func _clear_conditions() -> void:
	for child in _conditions_container.get_children():
		_conditions_container.remove_child(child)
		child.queue_free()

## Appends one row (property name + inline [BehaviorGraphNodeVariableEditor]) for [param property],
## belonging to [param node], to [member _properties_container].
func _add_property_row(node: BehaviorNode, property: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_properties_container.add_child(row)

	var name_label := Label.new()
	name_label.text = String(property["name"])
	name_label.custom_minimum_size = Vector2(110, 0)
	name_label.clip_text = true
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var editor: BehaviorGraphNodeVariableEditor = BEHAVIOR_GRAPH_NODE_VARIABLE.instantiate()
	editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(editor)

	if not editor.setup_variable_editor(node, property, _blackboard):
		push_warning("No available editor for \"%s\"" % property["name"])
		editor.queue_free()
		var fallback := Label.new()
		fallback.text = "{%s}" % property["name"]
		row.add_child(fallback)
	editor.var_property_editor.size_flags_horizontal=Control.SIZE_EXPAND_FILL
## Removes every row from [member _properties_container].
func _clear_properties() -> void:
	for child in _properties_container.get_children():
		_properties_container.remove_child(child)
		child.queue_free()
