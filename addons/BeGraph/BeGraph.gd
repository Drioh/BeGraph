@tool
extends EditorPlugin

var dock : EditorDock
var begraph_dock : Control
var file_dialog: EditorFileDialog
var _dock_added : bool = false

const BASE_CATEGORIES: Dictionary = {
	"action_node": [Color(0.161, 0.161, 0.161, 1.0), Color(0.824, 0.784, 0.745, 1.0)],
	"access_point_node": [Color(0.18, 0.396, 0.29, 1.0), Color(0.467, 1.0, 0.6, 1.0)],
	"control_flow_node": [Color(0.224, 0.196, 0.31, 1.0), Color(0.706, 0.58, 0.953, 1.0)],
	"comment_node": [Color(0.447, 0.318, 0.263, 1.0), Color(1.0, 0.722, 0.537, 1.0)],
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
	begraph_dock = preload("res://addons/BeGraph/UI/BeGraphDock.tscn").instantiate()
	dock = EditorDock.new()
	dock.add_child(begraph_dock)
	dock.title = "Behavior Graph"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
	var fs_dock = get_editor_interface().get_file_system_dock()
	fs_dock.resource_removed.connect(_on_resource_removed)
	_sync_settings()
	

func _exit_tree():
	_sync_settings(true)
	_remove_dock()
	var fs_dock = get_editor_interface().get_file_system_dock()
	fs_dock.resource_removed.disconnect(_on_resource_removed)
	dock.queue_free()

func _enable_plugin() -> void:
	pass

func _on_resource_removed (resource:Resource)->void:
	if resource == begraph_dock.loaded_graph:
		begraph_dock.load_graph(null)

func _disable_plugin() -> void:
	
	_remove_dock()

func _handles(object: Object) -> bool:
	return object is BehaviorGraph or object is BehaviorNode

func _edit(object: Object) -> void:
	if object is BehaviorGraph:
		_make_visible(true)
		if not begraph_dock.loaded_graph == object:
			if begraph_dock.loaded_graph != null:
				_on_save_pressed()
			begraph_dock.load_graph(object)

func _make_visible(visible: bool) -> void:
	if visible or EditorInterface.get_inspector().get_edited_object() is BehaviorGraph:
		_add_dock()
		dock.make_visible()
		if not begraph_dock.close_button.pressed.is_connected(_on_close_pressed):
			begraph_dock.close_button.pressed.connect(_on_close_pressed)
		if not begraph_dock.save_button.pressed.is_connected(_on_save_pressed):
			begraph_dock.save_button.pressed.connect(_on_save_pressed)
		if not begraph_dock.save_as_button.pressed.is_connected(_on_save_as_pressed):
			begraph_dock.save_as_button.pressed.connect(_on_save_as_pressed)
	else:
		_remove_dock()

func _add_dock() -> void:
	if not _dock_added:
		add_dock(dock)
		_dock_added = true

func _remove_dock() -> void:
	if _dock_added:
		remove_dock(dock)
		_dock_added = false

func _on_close_pressed() -> void:
	_remove_dock()

func _on_save_pressed() -> void:
	var result : int = ResourceSaver.save(begraph_dock.loaded_graph)
	if result == 0: 
		print("saving \"%s\" to path:%s"%[begraph_dock.loaded_graph,begraph_dock.loaded_graph.resource_path])
	else:
		print("Couldn't save resource %s"%begraph_dock.loaded_graph)

func _on_save_as_pressed()->void:
	file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.add_filter("*.tres", "Behavior Graph")
	file_dialog.current_file = "NewBehaviorGraph.tres"
	file_dialog.file_selected.connect(_on_file_selected)

	EditorInterface.get_base_control().add_child(file_dialog)
	file_dialog.popup_centered_ratio()

func _on_file_selected(path: String) -> void:
	ResourceSaver.save(begraph_dock.loaded_graph, path)
	EditorInterface.get_resource_filesystem().scan()
	begraph_dock.load_graph(load(path))
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
