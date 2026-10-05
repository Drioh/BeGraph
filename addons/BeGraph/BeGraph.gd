@tool
## Main [EditorPlugin] script for the BeGraph addon: registers the bottom dock used to edit [BehaviorGraph] resources, keeps a set of [ProjectSettings] (node category colors, blackboard-binding colors, node script path) in sync, wires up the dock's save/save-as/close buttons, and registers the live graph debugger ([BehaviorGraphDebuggerPlugin] + the [BehaviorGraphDebugBridge] autoload).
extends EditorPlugin

## The dock container added to the editor via [method EditorPlugin.add_dock].
var dock : EditorDock
## The root [Control] instantiated from [code]BeGraphDock.tscn[/code], containing the actual graph editor UI.
var begraph_dock : Control
## Tracks whether [member dock] is currently added to the editor, to avoid double add/remove calls.
var _dock_added : bool = false

var _pending_graph : BehaviorGraph = null

var _confirm_dialog : ConfirmationDialog

## The editor-side half of the live graph debugger, added to the Debugger bottom panel while this plugin is active.
var _debugger_plugin : BehaviorGraphDebuggerPlugin

const SETTINGS : Dictionary[String,Variant]={
	"BeGraph/colors/null_variable_color": Color(1.0, 0.0, 0.235, 1.0),
	"BeGraph/colors/node_colors/action_node/background": Color(0.161, 0.161, 0.161, 1.0),
	"BeGraph/colors/node_colors/action_node/border":Color(0.824, 0.784, 0.745, 1.0),
	"BeGraph/colors/node_colors/access_point_node/background": Color(0.075, 0.161, 0.157, 1.0),
	"BeGraph/colors/node_colors/access_point_node/border": Color(0.467, 1.0, 0.6, 1.0),
	"BeGraph/colors/node_colors/control_flow_node/background": Color(0.224, 0.196, 0.31, 1.0),
	"BeGraph/colors/node_colors/control_flow_node/border":Color(0.706, 0.58, 0.953, 1.0),
	"BeGraph/colors/node_colors/comment_node/background": Color(0.56, 0.43, 0.235, 0.784),
	"BeGraph/colors/node_colors/comment_node/border":Color(0.79, 0.564, 0.269, 1.0),
	"BeGraph/colors/node_colors/run_subgraph_node/background": Color(0.176, 0.118, 0.118, 1.0),
	"BeGraph/colors/node_colors/run_subgraph_node/border": Color(0.58, 0.161, 0.169, 1.0),
	"BeGraph/colors/node_colors/custom_categories": [] as PackedStringArray,
	"BeGraph/colors/graph_editor/allowed_variable/background":Color(0.149, 0.176, 0.145, 1.0),
	"BeGraph/colors/graph_editor/allowed_variable/border":Color(0.267, 0.475, 0.239, 1.0),
	"BeGraph/colors/graph_editor/not_allowed_variable/background":Color(0.176, 0.118, 0.118, 1.0),
	"BeGraph/colors/graph_editor/not_allowed_variable/border":Color(0.58, 0.161, 0.169, 1.0)
}

const NODE_COLORS_PREFIX :String= "BeGraph/colors/node_colors"

## Autoload name under which [constant DEBUG_BRIDGE_SCRIPT_PATH] is registered while this plugin is active.
const DEBUG_BRIDGE_AUTOLOAD_NAME :String= "BeGraphDebugBridge"
## Script driving the runtime side of the live graph debugger; auto-registered as an autoload so agents get streamed to the editor with no manual setup.
const DEBUG_BRIDGE_SCRIPT_PATH :String= "res://addons/BeGraph/Debug/BehaviorGraphDebugBridge.gd"

# Instantiates the dock scene, configures it as a bottom, horizontally- or floating-dockable panel, listens for resource deletions in the filesystem dock (to unload a graph being edited if its file gets removed), syncs the addon's [ProjectSettings], and registers the live graph debugger.
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

	_debugger_plugin = BehaviorGraphDebuggerPlugin.new()
	add_debugger_plugin(_debugger_plugin)
	add_autoload_singleton(DEBUG_BRIDGE_AUTOLOAD_NAME, DEBUG_BRIDGE_SCRIPT_PATH)
	
	begraph_dock.ready.connect(_connect_dock_buttons, CONNECT_ONE_SHOT)
	

# Removes every [ProjectSettings] entry written by this addon, removes the dock, unregisters the live graph debugger, and disconnects the filesystem-dock signal.
func _exit_tree():
	_remove_dock()
	var fs_dock = get_editor_interface().get_file_system_dock()
	fs_dock.resource_removed.disconnect(_on_resource_removed)
	fs_dock.files_moved.disconnect(_on_files_moved)
	_confirm_dialog.queue_free()
	dock.queue_free()

	remove_autoload_singleton(DEBUG_BRIDGE_AUTOLOAD_NAME)
	remove_debugger_plugin(_debugger_plugin)
	_debugger_plugin = null

# Called when the plugin is enabled; currently a no-op.
func _enable_plugin() -> void:
	pass

func _connect_dock_buttons() -> void:
	begraph_dock.close_button.pressed.connect(_remove_dock)
	begraph_dock.save_button.pressed.connect(_on_save_pressed)
	begraph_dock.save_as_button.pressed.connect(_on_save_as_pressed)
	begraph_dock.new_button.pressed.connect(_on_new_pressed)
	begraph_dock.load_button.pressed.connect(_on_load_pressed)
	begraph_dock.embed_button.pressed.connect(_on_embed_pressed)

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

func _on_embed_pressed() -> void:
	if begraph_dock.loaded_graph == null:
		push_error("Open a Behavior Graph before embedding another one into it")
		return
	_open_file_dialog(EditorFileDialog.FILE_MODE_OPEN_FILE, func(path: String):
		var res := load(path)
		if res is BehaviorGraph:
			begraph_dock.graph_edit.embed_graph(res)
		else:
			push_error("\"%s\" is not a valid Behavior Graph" % path)
	)

func _disable_plugin() -> void: 
	_remove_dock()

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
	_open_file_dialog(EditorFileDialog.FILE_MODE_SAVE_FILE, func(path: String):
		if _save_graph_to(graph, path):
			on_saved.call()
	)

func _on_save_pressed() -> void:
	_save_loaded_graph(func():
		print("saved \"%s\" to %s" % [begraph_dock.loaded_graph, begraph_dock.loaded_graph.resource_path])
	)

func _on_save_as_pressed() -> void:
	_open_file_dialog(EditorFileDialog.FILE_MODE_SAVE_FILE, func(path: String):
		if _save_graph_to(begraph_dock.loaded_graph, path):
			begraph_dock.load_graph(load(path))
	)

func _on_new_pressed() -> void:
	_request_open_graph(BehaviorGraph.new())

func _on_load_pressed() -> void:
	_open_file_dialog(EditorFileDialog.FILE_MODE_OPEN_FILE, func(path: String):
		var res := load(path)
		if res is BehaviorGraph:
			_request_open_graph(res)
		else:
			push_error("\"%s\" is not a valid Behavior Graph" % path)
	)

## Creates a EditorFileDialog (.tres), shows it and frees it automatically when it gets closed.
func _open_file_dialog(mode: EditorFileDialog.FileMode, on_selected: Callable) -> void:
	var d := EditorFileDialog.new()
	d.file_mode = mode
	d.access = EditorFileDialog.ACCESS_RESOURCES
	d.add_filter("*.tres", "Behavior Graph")
	if mode == EditorFileDialog.FILE_MODE_SAVE_FILE:
		d.current_file = "NewBehaviorGraph.tres"
	d.file_selected.connect(func(path: String):
		on_selected.call(path)
		d.queue_free()
	)
	d.canceled.connect(d.queue_free)
	EditorInterface.get_base_control().add_child(d)
	d.popup_centered_ratio()

## Saves [param graph] in [param path] and scans the filesystem to reload it. Returns true if save is successful.
func _save_graph_to(graph: Resource, path: String) -> bool:
	var err := ResourceSaver.save(graph, path)
	if err != OK:
		push_error("Couldn't save resource %s to %s (error %d)" % [graph, path, err])
		return false
	EditorInterface.get_resource_filesystem().scan()
	return true

#endregion
#region SETTINGS

## Writes every [ProjectSettings] entry owned by this addon: the node-scripts path, the null-variable color, the custom-categories list, the blackboard drag/drop colors, and the background/border colors for every base and custom node category. [br]
## Clears settings in the process if [param remove_all] is [code]true[/code]).
func _sync_settings() -> void:

	for key in SETTINGS:
		_write_setting(key, SETTINGS[key])
	
	for key in ProjectSettings.get_setting("BeGraph/colors/node_colors/custom_categories"):
		if !ProjectSettings.has_setting(key):
			_write_setting(NODE_COLORS_PREFIX+"/"+key+"/background",Color(1.0, 1.0, 1.0, 1.0))
			_write_setting(NODE_COLORS_PREFIX+"/"+key+"/border",Color(0.0, 0.0, 0.0, 1.0))

## Sets [param key] to [param default_value] in [ProjectSettings] (unless it already exists and [param overwrite] is [code]false[/code]), registers its initial value and property info (with the given [param hint]), and marks it as a "basic" setting so it's visible without enabling advanced settings.
func _write_setting(key: String, default_value, hint: int = PROPERTY_HINT_NONE, overwrite: bool = false) -> void:
	if overwrite or not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({"name": key, "type": typeof(default_value), "hint": hint})
	ProjectSettings.set_as_basic(key, true)

#endregion
