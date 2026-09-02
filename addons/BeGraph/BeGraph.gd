@tool
extends EditorPlugin

var dock : EditorDock
var graph_edit : BehaviorGraphEdit

const BASE_CATEGORIES: Dictionary = {
	"action_node": [Color(0.161, 0.161, 0.161, 1.0), Color(0.824, 0.784, 0.745, 1.0)],
	"access_point_node": [Color(0.18, 0.396, 0.29, 1.0), Color(0.467, 1.0, 0.6, 1.0)],
	"control_flow_node": [Color(0.224, 0.196, 0.31, 1.0), Color(0.706, 0.58, 0.953, 1.0)],
	"conditional_node": [Color(0.447, 0.318, 0.263, 1.0), Color(1.0, 0.722, 0.537, 1.0)],
}

const NODES_PATH_KEY :String= "BeGraph/nodes_path"
const NULL_COLOR_KEY :String= "BeGraph/colors/null_variable_color"

const ALLOWED_VARIABLE_BG :String = "BeGraph/colors/allowed_variable_color_background"
const ALLOWED_VARIABLE_BORDER :String ="BeGraph/colors/allowed_variable_color_border"
const NOT_ALLOWED_VARIABLE_BG :String ="BeGraph/colors/not_allowed_variable_color_background"
const NOT_ALLOWED_VARIABLE_BORDER :String ="BeGraph/colors/not_allowed_variable_color_border"

const CUSTOM_CATEGORIES_KEY :String= "BeGraph/colors/node_colors/custom_categories"
const COLORS_PREFIX :String= "BeGraph/colors/node_colors/"

func _enter_tree():
	graph_edit = preload("res://addons/BeGraph/UI/BehaviorGraphEdit.tscn").instantiate()
	dock = EditorDock.new()
	dock.add_child(graph_edit)
	dock.title = "Behavior Graph"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
	add_dock(dock)
	_sync_settings()
	dock.close()

func _exit_tree():
	_sync_settings(true)
	if dock.is_visible_in_tree():
		remove_dock(dock)
		dock.queue_free()

func _enable_plugin() -> void: 
	if dock.is_visible_in_tree():
		dock.close()

func _disable_plugin() -> void:
	if dock.is_visible_in_tree():
		remove_dock(dock)
		dock.queue_free()

func _handles(object: Object) -> bool:
	return object is BehaviorGraph or object is BehaviorNode

func _edit(object: Object) -> void:
	if object is BehaviorGraph:
		graph_edit.set_graph(object)

func _make_visible(visible: bool) -> void:
	if visible:
		dock.make_visible()

#region SETTINGS

func _sync_settings(remove_all: bool = false) -> void:
	_write_setting(NODES_PATH_KEY, "res://addons/BeGraph/Classes/Nodes/", PROPERTY_HINT_DIR)
	_write_setting(NULL_COLOR_KEY, Color(0.8, 0.0, 0.133, 1.0))
	
	_write_setting(CUSTOM_CATEGORIES_KEY, PackedStringArray())
	
	_write_setting(ALLOWED_VARIABLE_BG, Color(0.149, 0.176, 0.145, 1.0))
	_write_setting(ALLOWED_VARIABLE_BORDER, Color(0.267, 0.475, 0.239, 1.0))
	_write_setting(NOT_ALLOWED_VARIABLE_BG, Color(0.176, 0.118, 0.118, 1.0))
	_write_setting(NOT_ALLOWED_VARIABLE_BORDER, Color(0.58, 0.161, 0.169, 1.0))

	var custom_ids: PackedStringArray = ProjectSettings.get_setting(CUSTOM_CATEGORIES_KEY, PackedStringArray())
	var valid_ids: Array = []
	for raw in custom_ids:
		var id := String(raw).strip_edges()
		if id != "" and not BASE_CATEGORIES.has(id):
			valid_ids.append(id)

	# Creates and updates colors for base and custom categories
	if not remove_all:
		for id in BASE_CATEGORIES:
			_write_category_colors(id, BASE_CATEGORIES[id][0], BASE_CATEGORIES[id][1])
		for id in valid_ids:
			_write_category_colors(id, Color.DARK_SLATE_GRAY, Color.DARK_GRAY)

	# removes colors from invalid categories
	var allowed := {} if remove_all else BASE_CATEGORIES.duplicate()
	for id in valid_ids:
		allowed[id] = true

	for prop in ProjectSettings.get_property_list():
		var name: String = prop.get("name", "")
		if not name.begins_with(COLORS_PREFIX) or name == CUSTOM_CATEGORIES_KEY or name == NULL_COLOR_KEY:
			continue
		var id: String = name.trim_prefix(COLORS_PREFIX).get_slice("/", 0)
		if not allowed.has(id) and ProjectSettings.has_setting(name):
			ProjectSettings.clear(name)

	if remove_all:
		for key in [CUSTOM_CATEGORIES_KEY, NODES_PATH_KEY, NULL_COLOR_KEY]:
			if ProjectSettings.has_setting(key):
				ProjectSettings.clear(key)

func _write_category_colors(id: String, background: Color, border: Color) -> void:
	_write_setting("%s%s/background_color" % [COLORS_PREFIX, id], background, PROPERTY_HINT_NONE, false)
	_write_setting("%s%s/border_color" % [COLORS_PREFIX, id], border, PROPERTY_HINT_NONE, false)

# category write
func _write_setting(key: String, default_value, hint: int = PROPERTY_HINT_NONE, overwrite: bool = false) -> void:
	if overwrite or not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({"name": key, "type": typeof(default_value), "hint": hint})
	ProjectSettings.set_as_basic(key, true)

#endregion
