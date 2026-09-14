@tool
## Main [EditorPlugin] script for the BeGraph addon: registers the bottom dock used to edit [BehaviorGraph] resources, keeps a set of [ProjectSettings] (node category colors, blackboard-binding colors, node script path) in sync, and wires up the dock's save/save-as/close buttons.
extends EditorPlugin

## The dock container added to the editor via [method EditorPlugin.add_dock].
var dock : EditorDock
## The root [Control] instantiated from [code]BeGraphDock.tscn[/code], containing the actual graph editor UI.
var begraph_dock : Control
## File dialog used by [method _on_save_as_pressed] to pick a destination path for a new [BehaviorGraph] resource.
var file_dialog: EditorFileDialog
## Tracks whether [member dock] is currently added to the editor, to avoid double add/remove calls.
var _dock_added : bool = false

var _pending_graph : BehaviorGraph = null

var _confirm_dialog : ConfirmationDialog
## Default background/border colors for the built-in node categories, applied to [ProjectSettings] by [method _sync_settings]. Each entry maps a category id to a [code][background_color, border_color][/code] pair.
const BASE_CATEGORIES: Dictionary = {
	"action_node": [Color(0.161, 0.161, 0.161, 1.0), Color(0.824, 0.784, 0.745, 1.0)],
	"access_point_node": [Color(0.075, 0.161, 0.157, 1.0), Color(0.467, 1.0, 0.6, 1.0)],
	"control_flow_node": [Color(0.224, 0.196, 0.31, 1.0), Color(0.706, 0.58, 0.953, 1.0)],
	"comment_node": [Color(0.447, 0.318, 0.263, 1.0), Color(1.0, 0.722, 0.537, 1.0)],
}

## [ProjectSettings] key storing the directory scanned for available node scripts (see [constant BehaviorGraphEdit.NODE_PATH]).
const NODES_PATH_KEY :String= "BeGraph/nodes_path"
## [ProjectSettings] key storing the color used for a placeholder whose referenced key/value could not be resolved.
const NULL_COLOR_KEY :String= "BeGraph/colors/null_variable_color"

## [ProjectSettings] key storing the background color shown while dragging a blackboard variable over a compatible inline editor.
const ALLOWED_VARIABLE_BG :String = "BeGraph/colors/allowed_variable_color_background"
## [ProjectSettings] key storing the border color shown while dragging a blackboard variable over a compatible inline editor.
const ALLOWED_VARIABLE_BORDER :String ="BeGraph/colors/allowed_variable_color_border"
## [ProjectSettings] key storing the background color shown while dragging a blackboard variable over an incompatible inline editor.
const NOT_ALLOWED_VARIABLE_BG :String ="BeGraph/colors/not_allowed_variable_color_background"
## [ProjectSettings] key storing the border color shown while dragging a blackboard variable over an incompatible inline editor.
const NOT_ALLOWED_VARIABLE_BORDER :String ="BeGraph/colors/not_allowed_variable_color_border"

## [ProjectSettings] key storing the list of user-defined (custom) node category ids, in addition to [constant BASE_CATEGORIES].
const CUSTOM_CATEGORIES_KEY :String= "BeGraph/colors/node_colors/custom_categories"
## Common prefix for every per-category color [ProjectSettings] key (both base and custom categories).
const COLORS_PREFIX :String= "BeGraph/colors/node_colors/"

# Instantiates the dock scene, configures it as a bottom, horizontally- or floating-dockable panel, listens for resource deletions in the filesystem dock (to unload a graph being edited if its file gets removed), and syncs the addon's [ProjectSettings].
func _enter_tree():
	begraph_dock = preload("res://addons/BeGraph/UI/BeGraphDock.tscn").instantiate()
	dock = EditorDock.new()
	dock.add_child(begraph_dock)
	dock.title = "Behavior Graph"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL | EditorDock.DOCK_LAYOUT_FLOATING
	
	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.dialog_text = "Abandon current Behavior Graph without saving changes?"
	_confirm_dialog.ok_button_text = "Save changes and open a new graph"
	_confirm_dialog.cancel_button_text = "Cancel edit"
	_confirm_dialog.confirmed.connect(_on_abandon_confirmed)
	_confirm_dialog.canceled.connect(_on_abandon_canceled)
	EditorInterface.get_base_control().add_child(_confirm_dialog)
	
	var fs_dock = get_editor_interface().get_file_system_dock()
	fs_dock.resource_removed.connect(_on_resource_removed)
	fs_dock.files_moved.connect(_on_files_moved)
	_sync_settings()
	

# Removes every [ProjectSettings] entry written by this addon, removes the dock, and disconnects the filesystem-dock signal.
func _exit_tree():
	_sync_settings(true)
	_remove_dock()
	var fs_dock = get_editor_interface().get_file_system_dock()
	fs_dock.resource_removed.disconnect(_on_resource_removed)
	fs_dock.files_moved.disconnect(_on_files_moved)
	_confirm_dialog.queue_free()
	dock.queue_free()

# Called when the plugin is enabled; currently a no-op.
func _enable_plugin() -> void:
	pass

## Callback for [signal FileSystemDock.resource_removed]: unloads the currently edited graph (via [method BeGraphDock.load_graph]) if the removed resource is the one currently open in the dock.
func _on_resource_removed(resource: Resource) -> void:
	if resource == begraph_dock.loaded_graph:
		begraph_dock.load_graph(null)
		_remove_dock() # chiude la tab

func _on_files_moved(old_file: String, new_file: String) -> void:
	if begraph_dock.loaded_graph == null:
		return
	if begraph_dock.loaded_graph.resource_path == old_file or begraph_dock.loaded_graph.resource_path == new_file:
		begraph_dock.refresh_label()


func _disable_plugin() -> void: _remove_dock()

# Overrides [method EditorPlugin._handles]: this plugin's custom editing behavior applies to [BehaviorGraph] and [BehaviorNode] resources.
func _handles(object: Object) -> bool:
	return object is BehaviorGraph or object is BehaviorNode

# Overrides [method EditorPlugin._edit]: when a [BehaviorGraph] is selected for editing, shows the dock and loads the graph into it (saving the previously loaded graph first, if any, and if it's a different resource).
func _edit(object: Object) -> void:
	if object is BehaviorGraph:
		_make_visible(true)
		_request_open_graph(object)

# Overrides [method EditorPlugin._make_visible]: shows or hides the dock and, the first time it's made visible, connects the dock's close/save/save-as buttons to their handlers.
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
		if not begraph_dock.new_button.pressed.is_connected(_on_new_pressed):
			begraph_dock.new_button.pressed.connect(_on_new_pressed)
		if not begraph_dock.load_button.pressed.is_connected(_on_load_pressed):
			begraph_dock.load_button.pressed.connect(_on_load_pressed)
	else:
		_remove_dock()

## Adds [member dock] to the editor (via [method EditorPlugin.add_dock]) if it isn't already added.
func _add_dock() -> void:
	if not _dock_added:
		add_dock(dock)
		_dock_added = true

## Removes [member dock] from the editor if it is currently added.
func _remove_dock() -> void:
	if _dock_added:
		remove_dock(dock)
		_dock_added = false

## Callback for the dock's close button; hides the dock.
func _on_close_pressed() -> void:
	_remove_dock()

#region Graph opening / saving

func _request_open_graph(new_graph: BehaviorGraph) -> void:
	if new_graph == begraph_dock.loaded_graph:
		return
	if begraph_dock.loaded_graph != null:
		_pending_graph = new_graph
		_confirm_dialog.popup_centered()
	else:
		begraph_dock.load_graph(new_graph)

func _on_abandon_confirmed() -> void:
	var graph : BehaviorGraph = _pending_graph
	_pending_graph = null
	_save_loaded_graph(func(): begraph_dock.load_graph(graph))

func _on_abandon_canceled() -> void:
	var graph : BehaviorGraph = _pending_graph
	_pending_graph = null
	begraph_dock.load_graph(graph)

func _save_loaded_graph(on_saved: Callable) -> void:
	var graph : Resource = begraph_dock.loaded_graph
	var path : String = graph.resource_path
	if path == "" or not ResourceLoader.exists(path):
		_prompt_save_path(graph, on_saved)
		return
	if ResourceSaver.save(graph) != OK:
		push_error("Couldn't save resource %s" % graph)
		return
	on_saved.call()

func _prompt_save_path(graph: Resource, on_saved: Callable) -> void:
	var d := EditorFileDialog.new()
	d.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	d.access = EditorFileDialog.ACCESS_RESOURCES
	d.add_filter("*.tres", "Behavior Graph")
	d.current_file = "NewBehaviorGraph.tres"
	d.file_selected.connect(func(path: String):
		ResourceSaver.save(graph, path)
		EditorInterface.get_resource_filesystem().scan()
		on_saved.call()
		d.queue_free()
	)
	d.canceled.connect(d.queue_free)
	EditorInterface.get_base_control().add_child(d)
	d.popup_centered_ratio()

func _on_save_pressed() -> void:
	_save_loaded_graph(func():
		print("saved \"%s\" to %s" % [begraph_dock.loaded_graph, begraph_dock.loaded_graph.resource_path])
	)

func _on_save_as_pressed() -> void:
	file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.add_filter("*.tres", "Behavior Graph")
	file_dialog.current_file = "NewBehaviorGraph.tres"
	file_dialog.file_selected.connect(_on_file_selected)
	EditorInterface.get_base_control().add_child(file_dialog)
	file_dialog.popup_centered_ratio()

func _on_new_pressed() -> void:
	_request_open_graph(BehaviorGraph.new())

func _on_load_pressed() -> void:
	var d := EditorFileDialog.new()
	d.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	d.access = EditorFileDialog.ACCESS_RESOURCES
	d.add_filter("*.tres", "Behavior Graph")
	d.file_selected.connect(func(path: String):
		var res := load(path)
		if res is BehaviorGraph:
			_request_open_graph(res)
		else:
			push_error("\"%s\" is not a valid Behavior Graph" % path)
		d.queue_free()
	)
	d.canceled.connect(d.queue_free)
	EditorInterface.get_base_control().add_child(d)
	d.popup_centered_ratio()

#endregion

## Callback for [signal EditorFileDialog.file_selected] from the save-as dialog: saves the currently loaded graph to [param path], rescans the filesystem, and reloads the dock from the newly-saved file.
func _on_file_selected(path: String) -> void:
	ResourceSaver.save(begraph_dock.loaded_graph, path)
	EditorInterface.get_resource_filesystem().scan()
	begraph_dock.load_graph(load(path))
#region SETTINGS

## Writes every [ProjectSettings] entry owned by this addon: the node-scripts path, the null-variable color, the custom-categories list, the blackboard drag/drop colors, and the background/border colors for every base and custom node category. [br]
## Clears settings in the process if [param remove_all] is [code]true[/code]).
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
		var id :String= String(raw).strip_edges()
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

## Writes the [code]background_color[/code]/[code]border_color[/code] [ProjectSettings] pair for node category [param id].
func _write_category_colors(id: String, background: Color, border: Color) -> void:
	_write_setting("%s%s/background_color" % [COLORS_PREFIX, id], background, PROPERTY_HINT_NONE, false)
	_write_setting("%s%s/border_color" % [COLORS_PREFIX, id], border, PROPERTY_HINT_NONE, false)

## Sets [param key] to [param default_value] in [ProjectSettings] (unless it already exists and [param overwrite] is [code]false[/code]), registers its initial value and property info (with the given [param hint]), and marks it as a "basic" setting so it's visible without enabling advanced settings.
func _write_setting(key: String, default_value, hint: int = PROPERTY_HINT_NONE, overwrite: bool = false) -> void:
	if overwrite or not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({"name": key, "type": typeof(default_value), "hint": hint})
	ProjectSettings.set_as_basic(key, true)

#endregion
