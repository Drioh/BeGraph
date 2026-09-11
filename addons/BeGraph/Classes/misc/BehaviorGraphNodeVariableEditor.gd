@tool
## Inline editor control for a single [BehaviorNode] variable, shown inside a
## [BehaviorGraphNode]. Displays either a standard [EditorProperty] for the
## variable's value, or, when the variable is bound to a blackboard entry, a
## read-only reference label with an option to unlink it. Also supports
## drag-and-drop binding of blackboard variables of a compatible type.
class_name BehaviorGraphNodeVariableEditor
extends PanelContainer

## Property usage flags passed when instantiating the inline [EditorProperty].
const EDITOR_USAGES = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_NIL_IS_VARIANT |PROPERTY_USAGE_SCRIPT_VARIABLE
## Maps each [enum Variant.Type] to the list of [enum Variant.Type] values that
## are considered compatible with it, i.e. which blackboard variable types may
## be bound to a variable of a given type (used by [method _populate_popup],
## [method check_key], [method _can_drop_data] and [method _notification]).
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

## Container holding, in order: the blackboard-link/unlink UI and the inline
## [EditorProperty] (or blackboard reference label).
@onready var h_box_container: HBoxContainer = %HBoxContainer

## Icon representing the variable's [enum Variant.Type].
@onready var type_icon: TextureRect = %TypeIcon
## The [EditorProperty] instantiated for this variable's value, used when the
## variable is not bound to a blackboard entry.
var var_property_editor: EditorProperty
## Label shown instead of [member var_property_editor] when the variable is
## bound to a blackboard entry; displays the bound key's name.
@onready var bb_reference: Label = %BBReference
## Button that opens the blackboard-selection popup, used to bind this
## variable to a local or shared blackboard entry.
@onready var bb_link_button: MenuButton = %BBLinkButton
## Button used to remove an existing blackboard binding, reverting to the
## plain value editor.
@onready var bb_unlink_button: Button = %BBUnlinkButton
## Overlay panel used to give drag-and-drop visual feedback (valid/invalid
## drop target) while dragging a blackboard variable over this control.
@onready var fallback_layer: PanelContainer = %FallbackLayer

## Root popup shown by [member bb_link_button], containing the local and
## shared blackboard submenus.
@onready var popup :PopupMenu= bb_link_button.get_popup()

## The [enum Variant.Type] of the variable being edited. Setting it also
## refreshes [member type_icon].
@onready var type : int:
	set(value):
		type=value
		type_icon.texture=EditorInterface.get_editor_theme().get_icon(type_string(value),"EditorIcons")
## The name of the [BehaviorNode] property this control edits.
@onready var key : StringName = &""
## The [BehaviorNode] resource that owns the variable being edited.
@onready var node : BehaviorNode

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
			
@onready var linked : bool = false:
	set(value):
		if value:
			if var_property_editor: 
				var_property_editor.hide()
			bb_link_button.hide()
			bb_reference.show()
			bb_unlink_button.show()
		else:
			if var_property_editor: 
				var_property_editor.show()
			
			linked_property=null
			bb_link_button.show()
			bb_reference.hide()
			bb_unlink_button.hide()
		linked = value
## Initializes this control for editing property [param k] (of type [param t])
## on [param n], using [param l_bb] and [param s_bb] as the local/shared
## blackboards. Instantiates the matching [EditorProperty] via
## [method EditorInspector.instantiate_property_editor] and wires up value
## change propagation in both directions. Returns [code]false[/code] if no
## editor could be created for this property's type.
func setup_variable_editor(n : BehaviorNode,property:Dictionary,bb:Array[BlackboardVariable]) -> bool:
	node = n
	
	type = property["type"]
	key = property["name"]
	var hint : int = property["hint"]
	var hint_string: String =  property["hint_string"]
	var usage : int = property["usage"]
	
	var editor: EditorProperty = EditorInspector.instantiate_property_editor(
		node,
		type, 
		key, 
		hint, 
		hint_string, 
		EDITOR_USAGES|usage, 
		true
	)
	if editor == null:
		return false
	
	editor.set_object_and_property(node, key)
	editor.draw_label=false
	editor.selectable=false
	
	h_box_container.add_child(editor)
	h_box_container.move_child(editor,1)
	
	var_property_editor=editor
	var_property_editor.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var_property_editor.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	
	size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	editor.property_changed.connect(change_property)
	editor.update_property()
	node.changed.connect(editor.update_property)
	node.blackboard_key_set.connect(sync_blackboard_keys)
	
	bb_link_button.about_to_popup.connect(_populate_popup,CONNECT_DEFERRED)
	bb_unlink_button.pressed.connect(node.set_node_property_blackboard_key.bind(key))
	popup.index_pressed.connect(_on_popup_index_pressed)
	
	for child in get_all_children(editor):
		child.mouse_filter=Control.MOUSE_FILTER_PASS
	return true

## Callback for [signal EditorProperty.property_changed], forwarded from
## [member var_property_editor]; applies the new value to [member node].
func change_property(property: StringName, new_value: Variant, field: StringName, changing: bool) -> void:
	node.set(property, new_value)

func sync_blackboard_keys(k : StringName = &"",bb_key : StringName = &""):
	if key == k:
		if bb_key == &"":
			linked =false
		else:
			if var_property_editor.visible: 
				linked = true
				bb_reference.text = String(bb_key)

## Callback for [signal MenuButton.about_to_popup] on [member bb_link_button].
## Repopulates [member local_variable_submenu] and [member shared_variable_submenu]
## with the variables from each blackboard whose type is compatible with
## [member type] (per [constant CONVERSION_DICT]), each with its type icon.
func _populate_popup() -> void:
	popup.clear()
	var theme := EditorInterface.get_editor_theme()
	for blackboard_property in node._graph_ref.get_ref().blackboard:
		var t: int = typeof(blackboard_property.value)
		if t in CONVERSION_DICT[type]:
			popup.add_item(blackboard_property.name)
			popup.set_item_icon(-1, theme.get_icon(type_string(t), "EditorIcons"))
	
	if popup.item_count == 0:
		popup.add_item("no properties to pick from blackboard")
		popup.set_item_disabled(-1,true)

## Callback fired when an item is selected from [param sub_menu] (either
## [member local_variable_submenu] or [member shared_variable_submenu]).
## Switches the display to the blackboard reference label, binds [member node]'s
## property to the selected key via [method BehaviorNode.set_blackboard_reference],
## and (re)connects the appropriate blackboard's [signal Resource.changed]
## signal (and that of the bound variable) to [method check_key], making sure
## only one blackboard is listened to at a time.
func _on_popup_index_pressed(index : int) -> void:
	linked = true
	var property_name :String = popup.get_item_text(index)
	for property in node._graph_ref.get_ref().blackboard:
		if property.name == property_name:
			linked_property=property
	bb_reference.text = property_name
	node.set_node_property_blackboard_key(key, property_name)

## Returns [code]true[/code] if [param data] represents a blackboard variable
## resource whose value type is compatible with [member type] and the drop
## position lands on a valid slot within this control.
func _can_drop_data(at_position, data):
	var global_pos = get_global_transform() * at_position
	if (data.has("resource")):
		var cond_1:bool=_get_slot_at(self,global_pos)!=null and typeof(data["resource"].value) in CONVERSION_DICT[type]
		var cond_2 : bool = typeof(data["resource"].value) == TYPE_NIL
		return cond_1 or cond_2
	return false
## Handles a successful drop of a blackboard variable resource: determines
## whether it came from the local or shared blackboard (based on its resource
## path) and binds [member node]'s property to that blackboard/key via
## [method BehaviorNode.set_blackboard_reference].
func _drop_data(at_position, data):
	var k : StringName = data["resource"].name
	bb_reference.text = String(k)
	linked_property=data["resource"]
	node.set_node_property_blackboard_key(key, k)

func update_bb_name(n:StringName):
	bb_reference.text=n
	node.set_node_property_blackboard_key(key,n)

func update_bb_value(v:Variant):
	if not typeof(v) in CONVERSION_DICT[type]:
		node.set_node_property_blackboard_key(key)
		linked=false

## Recursively searches [param node]'s [Control] descendants for the one whose
## global rect contains [param global_pos], returning the first (deepest)
## match found, or [code]null[/code] if none does.
func _get_slot_at(node, global_pos):
	for child in node.get_children():
		if child is Control:
			if child.get_global_rect().has_point(global_pos):
				# se è già uno slot valido (foglia), ritornalo
				return child
			# continua comunque la ricorsione nei figli
			var found = _get_slot_at(child, global_pos)
			if found:
				return found
	return null

## Recursively collects [param in_node] and every one of its descendants into
## a flat array (appending to, and returning, [param arr]).
func get_all_children(in_node,arr:=[]):
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr

func check_property(blackboard:Array[BlackboardVariable])->void:
	if linked_property != null:
		if linked_property not in blackboard:
			node.set_node_property_blackboard_key(key)
			linked=false

## ovides drag-and-drop visual feedback: while a compatible/incompatible
## blackboard variable resource is being dragged over this control, tints
## [member fallback_layer] accordingly; clears the tint once the drag ends.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		var drag_data = get_viewport().gui_get_drag_data()
		var cond_1 : bool = drag_data.has("resource") and typeof(drag_data["resource"].value) in CONVERSION_DICT[type]
		var cond_2 : bool = typeof(drag_data["resource"].value) == TYPE_NIL
		if cond_1 or cond_2:
			fallback_layer.set_indexed("theme_override_styles/panel:bg_color",ProjectSettings.get_setting("BeGraph/colors/allowed_variable_color_background"))
			fallback_layer.set_indexed("theme_override_styles/panel:border_color",ProjectSettings.get_setting("BeGraph/colors/allowed_variable_color_border"))
		else:
			fallback_layer.set_indexed("theme_override_styles/panel:bg_color",ProjectSettings.get_setting("BeGraph/colors/not_allowed_variable_color_background"))
			fallback_layer.set_indexed("theme_override_styles/panel:border_color",ProjectSettings.get_setting("BeGraph/colors/not_allowed_variable_color_border"))
	if what == NOTIFICATION_DRAG_END:
		fallback_layer.set_indexed("theme_override_styles/panel:bg_color",Color(0.0, 0.0, 0.0, 0.0))
		fallback_layer.set_indexed("theme_override_styles/panel:border_color",Color(0.0, 0.0, 0.0, 0.0))
