@tool
## Inline editor control for a single [BehaviorNode] variable, shown inside a [BehaviorGraphNode]. Displays either a standard [EditorProperty] for the variable's value, or, when the variable is bound to a blackboard entry, a read-only reference label with an option to unlink it. Also supports drag-and-drop binding of blackboard variables of a compatible type.
class_name BehaviorGraphNodeVariableEditor
extends PanelContainer

## Property usage flags used when instantiating the inline [EditorProperty].
const EDITOR_USAGES = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE
## Maps each [enum Variant.Type] to the list of [enum Variant.Type] values that are considered compatible with it.
const CONVERSION_DICT: Dictionary = {
	TYPE_NIL: [
		TYPE_NIL,
	],

	TYPE_BOOL: [
		TYPE_BOOL,
		TYPE_INT,
		TYPE_FLOAT,
	],

	TYPE_INT: [
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_BOOL,
		TYPE_STRING,
	],

	TYPE_FLOAT: [
		TYPE_FLOAT,
		TYPE_INT,
		TYPE_BOOL,
		TYPE_STRING,
	],

	TYPE_STRING: [
		TYPE_STRING,
		TYPE_STRING_NAME,
		TYPE_NODE_PATH,
	],

	TYPE_VECTOR2: [
		TYPE_VECTOR2,
		TYPE_VECTOR2I,
	],

	TYPE_VECTOR2I: [
		TYPE_VECTOR2I,
		TYPE_VECTOR2,
	],

	TYPE_RECT2: [
		TYPE_RECT2,
		TYPE_RECT2I,
	],

	TYPE_RECT2I: [
		TYPE_RECT2I,
		TYPE_RECT2,
	],

	TYPE_VECTOR3: [
		TYPE_VECTOR3,
		TYPE_VECTOR3I,
	],

	TYPE_VECTOR3I: [
		TYPE_VECTOR3I,
		TYPE_VECTOR3,
	],

	TYPE_TRANSFORM2D: [
		TYPE_TRANSFORM2D,
	],

	TYPE_VECTOR4: [
		TYPE_VECTOR4,
		TYPE_VECTOR4I,
	],

	TYPE_VECTOR4I: [
		TYPE_VECTOR4I,
		TYPE_VECTOR4,
	],

	TYPE_PLANE: [
		TYPE_PLANE,
		TYPE_VECTOR3,
	],

	TYPE_QUATERNION: [
		TYPE_QUATERNION,
		TYPE_BASIS,
	],

	TYPE_AABB: [
		TYPE_AABB,
	],

	TYPE_BASIS: [
		TYPE_BASIS,
		TYPE_QUATERNION,
	],

	TYPE_TRANSFORM3D: [
		TYPE_TRANSFORM3D,
		TYPE_PROJECTION,
	],

	TYPE_PROJECTION: [
		TYPE_PROJECTION,
		TYPE_TRANSFORM3D,
	],

	TYPE_COLOR: [
		TYPE_COLOR,
		TYPE_STRING,
	],

	TYPE_STRING_NAME: [
		TYPE_STRING_NAME,
		TYPE_STRING,
	],

	TYPE_NODE_PATH: [
		TYPE_NODE_PATH,
		TYPE_STRING,
	],

	TYPE_RID: [
		TYPE_RID,
	],

	TYPE_OBJECT: [
		TYPE_OBJECT,
		TYPE_NIL,
	],

	TYPE_CALLABLE: [
		TYPE_CALLABLE,
	],

	TYPE_SIGNAL: [
		TYPE_SIGNAL,
	],

	TYPE_DICTIONARY: [
		TYPE_DICTIONARY,
	],

	TYPE_ARRAY: [
		TYPE_ARRAY,
	],

	TYPE_PACKED_BYTE_ARRAY: [
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_INT32_ARRAY: [
		TYPE_PACKED_INT32_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_INT64_ARRAY: [
		TYPE_PACKED_INT64_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_FLOAT32_ARRAY: [
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_FLOAT64_ARRAY: [
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_STRING_ARRAY: [
		TYPE_PACKED_STRING_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_VECTOR2_ARRAY: [
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_VECTOR3_ARRAY: [
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_COLOR_ARRAY: [
		TYPE_PACKED_COLOR_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_VECTOR4_ARRAY: [
		TYPE_PACKED_VECTOR4_ARRAY,
		TYPE_ARRAY,
	],
}
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
	
	node.changed.connect(var_property_editor.update_property,CONNECT_DEFERRED)
	node.blackboard_key_set.connect(sync_blackboard_keys)
	node.conditions_changed.connect(refresh_editor.bind(property),CONNECT_DEFERRED)
	
	bb_link_button.about_to_popup.connect(_populate_popup,CONNECT_DEFERRED)
	bb_unlink_button.pressed.connect(node.set_node_property_blackboard_key.bind(key))
	
	popup.index_pressed.connect(_on_popup_index_pressed)
	popup.clear()
	
	var saved_key: StringName = property["blackboard_key"]
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
	var new_signature : Array = _signature_for(property)
	if new_signature == _editor_signature:
		return 
	_editor_signature = new_signature
	
	if var_property_editor:
		var_property_editor.get_parent().remove_child(var_property_editor)
		var_property_editor.queue_free()
		var_property_editor = null

	type = property["type"]
	key = property["name"]
	
	var editor: EditorProperty = EditorInspector.instantiate_property_editor(
		node, type, key, property["hint"], property["hint_string"],
		EDITOR_USAGES | property["usage"], true
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
	
	editor.property_changed.connect(change_property,CONNECT_DEFERRED)
	editor.update_property()

## Callback for [signal EditorProperty.property_changed], forwarded from [member var_property_editor]: applies the new value to [member node].
func change_property(property: StringName, new_value: Variant, field: StringName, changing: bool) -> void:
	if not changing:
		node.set(property, new_value)

## Callback for [signal BehaviorNode.blackboard_key_set]: if the changed property matches [member key], updates [member linked] to reflect whether a blackboard key is now bound ([param bb_key] non-empty) or not.
func sync_blackboard_keys(k : StringName = &"",bb_key : StringName = &""):
	if key == k:
		if bb_key == &"":
			linked =false
		elif var_property_editor.visible: 
			linked = true
			bb_reference.text = String(bb_key)

## Callback for [signal MenuButton.about_to_popup] on [member bb_link_button]. Repopulates [member popup] with every variable from the owning graph's blackboard whose type is compatible with [member type] (per [constant CONVERSION_DICT]), each with its type icon; shows a disabled placeholder item if none is compatible.
func _populate_popup() -> void:
	popup.clear()
	var theme := EditorInterface.get_editor_theme()
	for blackboard_property in node._graph_ref.get_ref().blackboard:
		var t: int = typeof(blackboard_property.value)
		if t not in CONVERSION_DICT[type]:
			continue
		popup.add_item(blackboard_property.name)
		popup.set_item_icon(-1, theme.get_icon(type_string(t), "EditorIcons"))

	if popup.item_count == 0:
		popup.add_item("no properties to pick from blackboard")
		popup.set_item_disabled(-1,true)

## Callback fired when an item is selected from [member popup]. Switches the display to the blackboard reference label, binds [member node]'s property to the selected key via [method BehaviorNode.set_node_property_blackboard_key], and stores the matching [BlackboardVariable] in [member linked_property].
func _on_popup_index_pressed(index : int) -> void:
	linked = true
	var property_name :String = popup.get_item_text(index)
	for property in node._graph_ref.get_ref().blackboard:
		if property.name == property_name:
			linked_property=property
	bb_reference.text = property_name
	node.set_node_property_blackboard_key(key, property_name)

## Returns [code]true[/code] if [param data] represents a blackboard variable resource with a value type compatible with [member type].
func _can_drop_data(at_position, data):
	if data is not Dictionary:
		return false
	if not data.has("resource"):
		return false

	var global_pos = get_global_transform() * at_position
	var cond_1:bool=_get_slot_at(self,global_pos)!=null and typeof(data["resource"].value) in CONVERSION_DICT[type]
	var cond_2 : bool = typeof(data["resource"].value) == TYPE_NIL
	return cond_1 or cond_2

## Handles a successful drop of a blackboard variable resource: binds [member node]'s property to the dropped variable's name via [method BehaviorNode.set_node_property_blackboard_key] and updates [member linked_property]/[member bb_reference] accordingly.
func _drop_data(at_position, data):
	var k : StringName = data["resource"].name
	bb_reference.text = String(k)
	linked_property=data["resource"]
	node.set_node_property_blackboard_key(key, k)

## Callback for [signal BlackboardVariable.name_changed] on [member linked_property]: updates [member bb_reference] and re-binds [member node]'s property to the new name.
func update_bb_name(n:StringName)->void:
	bb_reference.text=n
	node.set_node_property_blackboard_key(key,n)

## Callback for [signal BlackboardVariable.value_changed] on [member linked_property]: if the new value's type is no longer compatible with [member type], unbinds the property and switches back to the plain value editor.
func update_bb_value(v:Variant)->void:
	if not typeof(v) in CONVERSION_DICT[type]:
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
	if linked_property != null:
		if linked_property not in blackboard:
			node.set_node_property_blackboard_key(key)
			linked=false

## Provides drag-and-drop visual feedback: while a compatible/incompatible blackboard variable resource is being dragged over this control, tints [member fallback_layer] accordingly; clears the tint once the drag ends.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var drag_data = get_viewport().gui_get_drag_data()
		if not drag_data.has("resource"):
			return
		
		var cond_1 : bool = typeof(drag_data["resource"].value) in CONVERSION_DICT[type]
		var cond_2 : bool = typeof(drag_data["resource"].value) == TYPE_NIL
		
		var prefix : String = "" if (cond_1 or cond_2) else "not_"
		var bg_color : Color = ProjectSettings.get_setting("BeGraph/colors/%sallowed_variable_color_background"%prefix)
		var border_color : Color = ProjectSettings.get_setting("BeGraph/colors/%sallowed_variable_color_border"%prefix)
		fallback_layer.set_indexed("theme_override_styles/panel:bg_color",bg_color)
		fallback_layer.set_indexed("theme_override_styles/panel:border_color",border_color)

	if what == NOTIFICATION_DRAG_END:
		fallback_layer.set_indexed("theme_override_styles/panel:bg_color",Color(0.0, 0.0, 0.0, 0.0))
		fallback_layer.set_indexed("theme_override_styles/panel:border_color",Color(0.0, 0.0, 0.0, 0.0))

func _signature_for(property: Dictionary) -> Array:
	return [property["type"], property["hint"], property["hint_string"], property["usage"]]
