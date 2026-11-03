@tool
## Inline editor control for a single [BehaviorNode] variable, shown inside a [BehaviorGraphNode]. Displays either a standard [EditorProperty] for the variable's value, or, when the variable is bound to a blackboard entry, a read-only reference label with an option to unlink it. Also supports drag-and-drop binding of blackboard variables of a compatible type.
class_name BehaviorGraphNodeVariableEditor
extends PanelContainer

## Property usage flags used when instantiating the inline [EditorProperty].
const EDITOR_USAGES = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE

## Container holding, in order: the blackboard-link/unlink UI and the inline [EditorProperty] (or blackboard reference label).
@onready var h_box_container: HBoxContainer = %HBoxContainer
## Icon representing the variable's [enum Variant.Type].
@onready var type_icon: TextureRect = %TypeIcon
## The [EditorProperty] instantiated for this variable's value, used when the variable is not bound to a blackboard entry.
var var_property_editor: EditorProperty
## Label shown instead of [member var_property_editor] when the variable is bound to a blackboard entry; displays the bound key's name.
@onready var bb_reference: Label = %BBReference
## Button that opens the blackboard-selection popup, used to bind this variable to a local or shared blackboard entry.
@onready var bb_link_button: MenuButton = %BBLinkButton
## Button used to remove an existing blackboard binding, reverting to the plain value editor.
@onready var bb_unlink_button: Button = %BBUnlinkButton
## Overlay panel used to give drag-and-drop visual feedback (valid/invalid drop target) while dragging a blackboard variable over this control.
@onready var fallback_layer: PanelContainer = %FallbackLayer

## Root popup shown by [member bb_link_button], containing the available blackboard variables compatible with [member type].
@onready var popup :PopupMenu= bb_link_button.get_popup()

## The [enum Variant.Type] of the variable being edited. Setting it also refreshes [member type_icon].
@onready var type : int:
	set(value):
		type=value
		type_icon.texture=EditorInterface.get_editor_theme().get_icon(type_string(value),"EditorIcons")
## The name of the [BehaviorNode] property this control edits.
@onready var key : StringName = &""
## The [BehaviorNode] resource that owns the variable being edited.
@onready var node : BehaviorNode

var _editor_signature: Array = []

## The owning BehaviorGraphEdit, used to record undo/redo actions for property edits and
## blackboard (un)links. Set by whoever instantiates this control - BehaviorGraphNode (via its own
## already-exported graph_edit) or BehaviorNodeInfoPanel (via its own graph_edit, set once by
## BeGraphDock). Left null, this control still works, it simply won't record undo/redo steps.
var graph_edit : BehaviorGraphEdit = null

## True while a multi-step edit (e.g. dragging a slider) is in progress: set on the first
## property_changed call of a sequence, cleared once it's committed (changing == false).
var _editing : bool = false
## "Before" snapshot captured at the start of the current edit sequence (see
## BehaviorNode.capture_property_snapshot/apply_property_snapshot).
var _edit_before_snapshot : Dictionary = {}

## The [BlackboardVariable] currently bound to this control, [code]null[/code] if the variable isn't bound to a blackboard entry.
var linked_property : BlackboardVariable = null:
	set(v):
		if v:
			linked_property=v
			if linked_property.name_changed.is_connected(update_bb_name):
				linked_property.name_changed.disconnect(update_bb_name)
			linked_property.name_changed.connect(update_bb_name)
			
			if linked_property.value_changed.is_connected(update_bb_value):
				linked_property.value_changed.disconnect(update_bb_value)
			linked_property.value_changed.connect(update_bb_value)
			
			if node._graph_ref.get_ref().changed.is_connected(check_property):
				node._graph_ref.get_ref().changed.disconnect(check_property)
			node._graph_ref.get_ref().changed.connect(check_property)
			
## Whether blackboard reference or the plain value editor is displayed. Setting this toggles the visibility of those two pairs of controls accordingly, and clears [member linked_property] when switched back off.
@onready var linked : bool = false:
	set(value):
		if !value:
			linked_property = null
		if var_property_editor: 
			var_property_editor.visible = !value
		bb_link_button.visible = !value
		bb_reference.visible = value
		bb_unlink_button.visible = value
		linked = value

## Initializes this control for editing [param property] on [param n], using [param bb] as the graph's blackboard. Instantiates the matching [EditorProperty] via [method EditorInspector.instantiate_property_editor] and wires up value change propagation in both directions, restoring an existing blackboard binding if [param property] has one saved. Returns [code]false[/code] if no editor could be created for this property's type.
func setup_variable_editor(n : BehaviorNode,property:Dictionary,bb:Array[BlackboardVariable]) -> bool:
	node = n
	
	refresh_editor(property)

	size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	
	node.changed.connect(func():var_property_editor.update_property(),CONNECT_DEFERRED)
	node.blackboard_key_set.connect(sync_blackboard_keys)
	node.conditions_changed.connect(refresh_editor.bind(property),CONNECT_DEFERRED)
	
	bb_link_button.about_to_popup.connect(_populate_popup,CONNECT_DEFERRED)
	bb_unlink_button.pressed.connect(_on_unlink_pressed)
	
	popup.index_pressed.connect(_on_popup_index_pressed)
	popup.clear()
	
	var saved_key: StringName = node.get_blackboard_key(key)
	if saved_key == &"":
		return true

	for v in bb:
		if v.name!=saved_key:
			continue
		linked_property=v
		bb_reference.text=saved_key
		linked=true
	return true

## Rebuilds [member var_property_editor] from scratch using the [param property] info dictionary.[br]
## Used when the underlying property's type/hint changes dynamically, e.g. after [signal BehaviorNode.conditions_changed] fires for an enum-backed value.
func refresh_editor(property: Dictionary) -> void:
	_editing = false
	_edit_before_snapshot = {}

	type = property["type"]
	key = property["name"]
	
	var split_hint_string :PackedStringArray = property["hint_string"].split(":",false,2)
	var hint_string : String = split_hint_string[2] if split_hint_string.size()>2 else ""
	if property["hint"]==BG.HINT_ENUM and property["hint_string"].begins_with(BG.ENUMERATOR):
		var constant_map : Dictionary = node.get_script().get_script_constant_map()
		if constant_map.has(hint_string):
			hint_string = str(node.get_script().get_script_constant_map()[hint_string])
			hint_string = hint_string.trim_prefix("{").trim_suffix("}")
			hint_string = hint_string.remove_char(34).remove_char(32)
			hint_string = hint_string.replace_char(95,32).to_lower()
		elif node.get(hint_string) && node.get(hint_string) is PackedStringArray:
			hint_string = str(node.get(hint_string)).trim_prefix("[").trim_suffix("]")
			hint_string = hint_string.remove_char(34)
	
	var new_signature : Array = [type, property["hint"], hint_string, property["usage"]]
	
	if new_signature == _editor_signature:
		return #no need for this editor to refresh, its signature hasn't changed
	_editor_signature = new_signature
	
	if var_property_editor:
		var_property_editor.get_parent().remove_child(var_property_editor)
		var_property_editor.queue_free()
		var_property_editor = null

	var editor: EditorProperty = EditorInspector.instantiate_property_editor(
		node, 
		type, 
		key, 
		property["hint"], 
		hint_string,
		EDITOR_USAGES | property["usage"], 
		true
	)
	if editor == null:
		return

	editor.set_object_and_property(node, key)
	editor.draw_label = false
	editor.draw_background=false
	editor.selectable = false
	
	h_box_container.add_child(editor)
	h_box_container.move_child(editor, 1)

	var_property_editor = editor
	var_property_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var_property_editor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	editor.property_changed.connect(_on_property_changed,CONNECT_DEFERRED)
	editor.update_property()

## Callback for [signal EditorProperty.property_changed], forwarded from [member var_property_editor]: applies the new value to [member node].
func change_property(property: StringName, new_value: Variant, field: StringName, changing: bool) -> void:
	if node._set(property, new_value): return
	
	if type==TYPE_PACKED_STRING_ARRAY and node.get_node_property_info(property,"hint_string").begins_with(BG.CONDITION):
		var old_value:Variant = node.get(property)
		node.set(property, new_value)
		var previous_size:int = old_value.size()
		if previous_size==0:
			node.set(property,PackedStringArray(["Value 0"])) # if the array gets a 0 size, it gets populated with a single value "Value 0"
		if previous_size<new_value.size():
			node.get(property)[-1]="new enum value" # if the action performed is a new entry creation, initializes it to "new enum value"
		
		var values = node.get(property)
		var old_conditions : Array[Dictionary] = node.conditions.duplicate(true)
		node.conditions.clear()
		for i in values.size():
			var cond : bool = i < old_conditions.size()
			var kept_next : WeakRef = old_conditions[i]["next"] if cond else null
			node.conditions.append({"text": values[i], "next": kept_next})
			
		node.output = false
		node.conditions_changed.emit()
		
		# an element gets added or removed, so that previous size is both valid anddifferent than the old value
		var cond_1 : bool = previous_size != -1 and previous_size != values.size()
		# happens specifically when value gets set via the enter button when editing anentry
		var cond_2 : bool = old_value==node.get(property)
		if cond_1 or cond_2: 
			notify_property_list_changed.call_deferred()
		node.emit_changed()
		return
		
	node.set(property, new_value)
	node.emit_changed()

## Wraps change_property(): captures a full property snapshot at the start of an edit sequence
## (the first call, whether or not it is later followed by more "changing=true" calls, e.g. a
## slider drag), lets change_property() do its usual job unchanged, and commits a single undo/redo
## step only once the sequence finishes (changing == false). This mirrors how Godot's own inspector
## avoids recording one undo step per dragged frame.
func _on_property_changed(property: StringName, new_value: Variant, field: StringName, changing: bool) -> void:
	if not _editing:
		_edit_before_snapshot = node.capture_property_snapshot(property)
		_editing = true

	change_property(property, new_value, field, changing)

	if not changing:
		_commit_property_change(property)

## Commits the undo/redo step for the edit sequence that just finished on [param property].
## No-ops if nothing actually changed (e.g. a click that didn't move a slider).
func _commit_property_change(property: StringName) -> void:
	_editing = false
	var before : Dictionary = _edit_before_snapshot
	_edit_before_snapshot = {}

	if graph_edit == null or graph_edit.undo_redo == null:
		return
	var after : Dictionary = node.capture_property_snapshot(property)
	if after == before:
		return

	var target_node : BehaviorNode = node
	graph_edit.undo_redo.create_action("Edit %s" % property, UndoRedo.MERGE_DISABLE, graph_edit.current_graph)
	graph_edit.undo_redo.add_do_method(target_node, &"apply_property_snapshot", property, after)
	graph_edit.undo_redo.add_undo_method(target_node, &"apply_property_snapshot", property, before)
	graph_edit.undo_redo.commit_action(false)

## Callback for [signal BehaviorNode.blackboard_key_set]: if the changed property matches [member key], updates [member linked] to reflect whether a blackboard key is now bound ([param bb_key] non-empty) or not.
func sync_blackboard_keys(k : StringName = &"",bb_key : StringName = &""):
	if key != k: return
	if bb_key == &"":
		linked = false
		return
	if not var_property_editor.visible: return

	linked = true
	bb_reference.text = String(bb_key)
	var graph : BehaviorGraph = node.get_graph()
	if graph == null: return
	for v in graph.blackboard:
		if v.name == bb_key:
			linked_property = v
			break

## Callback for [signal MenuButton.about_to_popup] on [member bb_link_button]. Repopulates [member popup] with every variable from the owning graph's blackboard whose type is compatible with [member type] (per [constant CONVERSION_DICT]), each with its type icon; shows a disabled placeholder item if none is compatible.
func _populate_popup() -> void:
	popup.clear()
	var theme := EditorInterface.get_editor_theme()
	for blackboard_property in node._graph_ref.get_ref().blackboard:
		var t: int = typeof(blackboard_property.value)
		if t not in BG.CONVERSION_DICT[type]:
			continue
		popup.add_item(blackboard_property.name)
		popup.set_item_icon(-1, theme.get_icon(type_string(t), "EditorIcons"))

	if popup.item_count == 0:
		popup.add_item("no properties to pick from blackboard")
		popup.set_item_disabled(-1,true)

## Callback fired when an item is selected from [member popup]. Switches the display to the blackboard reference label, binds [member node]'s property to the selected key via [method BehaviorNode.set_node_property_blackboard_key], and stores the matching [BlackboardVariable] in [member linked_property].
func _on_popup_index_pressed(index : int) -> void:
	var property_name :String = popup.get_item_text(index)
	var new_key := StringName(property_name)
	var before_key : StringName = node.get_blackboard_key(key)

	linked = true
	for property in node._graph_ref.get_ref().blackboard:
		if property.name == new_key:
			linked_property=property
	bb_reference.text = property_name
	node.set_node_property_blackboard_key(key, new_key)

	_commit_blackboard_binding(before_key, new_key)

## Replaces the direct node.set_node_property_blackboard_key.bind(key) connection used previously,
## so an unlink click also records undo/redo.
func _on_unlink_pressed() -> void:
	var before_key : StringName = node.get_blackboard_key(key)
	node.set_node_property_blackboard_key(key)
	_commit_blackboard_binding(before_key, &"")

## Returns [code]true[/code] if [param data] represents a blackboard variable resource with a value type compatible with [member type].
func _can_drop_data(at_position, data):
	if data is not Dictionary:
		return false
	if not data.has("resource"):
		return false

	var global_pos = get_global_transform() * at_position
	var cond_1:bool=_get_slot_at(self,global_pos)!=null and typeof(data["resource"].value) in BG.CONVERSION_DICT[type]
	var cond_2 : bool = typeof(data["resource"].value) == TYPE_NIL
	return cond_1 or cond_2 or type==TYPE_NIL

## Handles a successful drop of a blackboard variable resource: binds [member node]'s property to the dropped variable's name via [method BehaviorNode.set_node_property_blackboard_key] and updates [member linked_property]/[member bb_reference] accordingly.
func _drop_data(at_position, data):
	var k : StringName = data["resource"].name
	var before_key : StringName = node.get_blackboard_key(key)

	bb_reference.text = String(k)
	linked_property=data["resource"]
	node.set_node_property_blackboard_key(key, k)

	_commit_blackboard_binding(before_key, k)

## Shared undo/redo primitive for every way of linking or unlinking a property (popup, drag&drop,
## unlink button): both do and undo call only node.set_node_property_blackboard_key(), never touch
## this control directly. This is deliberate - the resource (node) survives a delete+undo cycle
## unchanged, but this very control instance does not (a recreated node gets a brand new editor),
## so capturing "self" here would leave stale references in the undo history. Whichever control
## instance is alive when do/undo runs resyncs itself automatically via sync_blackboard_keys(),
## already connected to node.blackboard_key_set in setup_variable_editor().
func _commit_blackboard_binding(before_key: StringName, after_key: StringName) -> void:
	if before_key == after_key:
		return
	if graph_edit == null or graph_edit.undo_redo == null:
		return

	var target_node : BehaviorNode = node
	var target_key : StringName = key
	var action_name : String = ("Link %s" % key) if after_key != &"" else ("Unlink %s" % key)

	graph_edit.undo_redo.create_action(action_name, UndoRedo.MERGE_DISABLE, graph_edit.current_graph)
	graph_edit.undo_redo.add_do_method(target_node, &"set_node_property_blackboard_key", target_key, after_key)
	graph_edit.undo_redo.add_undo_method(target_node, &"set_node_property_blackboard_key", target_key, before_key)
	graph_edit.undo_redo.commit_action(false)

## Callback for [signal BlackboardVariable.name_changed] on [member linked_property]: updates [member bb_reference] and re-binds [member node]'s property to the new name.
func update_bb_name(n:StringName)->void:
	bb_reference.text=n
	node.set_node_property_blackboard_key(key,n)

## Callback for [signal BlackboardVariable.value_changed] on [member linked_property]: if the new value's type is no longer compatible with [member type], unbinds the property and switches back to the plain value editor.
func update_bb_value(v:Variant)->void:
	if not typeof(v) in BG.CONVERSION_DICT[type]:
		node.set_node_property_blackboard_key(key)
		linked=false

## Recursively searches [param node]'s [Control] descendants for the one whose global rect contains [param global_pos], returning the first (deepest) match found, or [code]null[/code] if none does.
func _get_slot_at(node, global_pos):
	for child in node.get_children():
		if child is Control:
			if child.get_global_rect().has_point(global_pos):
				# if leaf, return
				return child
			# continue recursion
			var found = _get_slot_at(child, global_pos)
			if found:
				return found
	return null

## Callback for the owning [BehaviorGraph]'s [signal Resource.changed]: unbinds [member linked_property] (reverting to the plain value editor) if it is no longer present in [param blackboard].
func check_property(blackboard:Array[BlackboardVariable])->void:
	if linked_property == null: return
	if linked_property in blackboard: return
	
	node.set_node_property_blackboard_key(key)
	linked = false

## Provides drag-and-drop visual feedback: while a compatible/incompatible blackboard variable resource is being dragged over this control, tints [member fallback_layer] accordingly; clears the tint once the drag ends.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var drag_data = get_viewport().gui_get_drag_data()
		if not drag_data.has("resource"):
			return
		
		var cond_1 : bool = typeof(drag_data["resource"].value) in BG.CONVERSION_DICT[type]
		var cond_2 : bool = typeof(drag_data["resource"].value) == TYPE_NIL

		var prefix : String = "" if (cond_1 or cond_2 or type==TYPE_NIL) else "not_"
		var bg_color : Color = ProjectSettings.get_setting("BeGraph/colors/graph_editor/%sallowed_variable/background"%prefix)
		var border_color : Color = ProjectSettings.get_setting("BeGraph/colors/graph_editor/%sallowed_variable/border"%prefix)
		fallback_layer.set_indexed("theme_override_styles/panel:bg_color",bg_color)
		fallback_layer.set_indexed("theme_override_styles/panel:border_color",border_color)

	if what == NOTIFICATION_DRAG_END:
		fallback_layer.set_indexed("theme_override_styles/panel:bg_color",Color(0.0, 0.0, 0.0, 0.0))
		fallback_layer.set_indexed("theme_override_styles/panel:border_color",Color(0.0, 0.0, 0.0, 0.0))
