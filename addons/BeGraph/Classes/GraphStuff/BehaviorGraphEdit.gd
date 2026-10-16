@tool
## A [GraphEdit] that visually builds and edits a [BehaviorGraph]: creates nodes from a categorized popup (built from [constant NODE_PATH]), handles connecting/disconnecting them, and keeps the underlying [BehaviorNode] resources in sync with the visual graph.
class_name BehaviorGraphEdit
extends GraphEdit

#region Constants

## Root directory scanned for node scripts to populate the creation popup. Subdirectories become submenus.
const NODE_PATH = "res://addons/BeGraph/Classes/Nodes/"

## ProjectSettings key holding additional node directories (PackedStringArray) to scan.
const CUSTOM_NODES_PATHS_SETTING = "BeGraph/general_settings/custom_nodes_paths"

## Scene instantiated for each new [BehaviorGraphNode].
const NODE = preload("res://addons/BeGraph/UI/BehaviorGraphNode.tscn")

## Offset (graph coordinates) applied to duplicated nodes so they don't land exactly on top of the originals.
const DUPLICATE_OFFSET := Vector2(40, 40)

## Snapshot taken by [method copy_selected_nodes]: [code]{"nodes": Array[BehaviorNode], "connections": Array[Dictionary]}[/code].[br]
## It only holds [BehaviorNode] resources (never visual [GraphNode]s), detached from any graph.
var _clipboard : Dictionary = {}

#endregion

#region State

## The [BehaviorGraph] currently being edited.
var current_graph: BehaviorGraph

var undo_redo: EditorUndoRedoManager

## Root popup shown for node creation, rebuilt from [constant NODE_PATH] on each request.
var _node_popup: PopupMenu

## Node that gets update when connection_to_empty gets fired
var _pending_connection_from: Dictionary = {}
#endregion

## Emitted whenever the selection changes to a single [BehaviorGraphNodeBase]; carries its
## underlying [BehaviorNode], or [code]null[/code] when nothing is selected.
signal selected_node_changed(node: BehaviorNode)

#region Lifecycle

## Connects [GraphEdit]'s node/connection/popup signals to their handlers.
func _ready() -> void:
	delete_nodes_request.connect(_on_delete_nodes_request)
	connection_request.connect(connect_nodes)
	connection_to_empty.connect(_on_connection_to_empty)
	disconnection_request.connect(disconnect_nodes)
	popup_request.connect(_on_popup_request)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)
	
	copy_nodes_request.connect(copy_selected_nodes)
	cut_nodes_request.connect(_on_cut_nodes_request)
	paste_nodes_request.connect(_on_paste_nodes_request)
	duplicate_nodes_request.connect(duplicate_selected_nodes)
	
	graph_elements_linked_to_frame_request.connect(_on_elements_linked_to_frame)
	end_node_move.connect(_sync_frame_attachments)
	begin_node_move.connect(_on_begin_node_move)
	end_node_move.connect(_on_end_node_move)
	if Engine.is_editor_hint():
		undo_redo = EditorInterface.get_editor_undo_redo()
#endregion


#region Graph loading

## Clears the current visual graph (connections and [BehaviorGraphNode] children), loads [param graph] as [member current_graph], and rebuilds it via [method load_nodes] and [method load_connections].
func set_graph(graph: BehaviorGraph) -> void:
	current_graph = null
	selected_node_changed.emit(null)

	if connections.size() > 0:
		clear_connections()

	for child in get_children().duplicate():
		if child is not BehaviorGraphNodeBase and child is not BehaviorGraphFrame:
			continue
		remove_child(child)
		child.free()
	current_graph = graph

	var frames : Array[BehaviorFrame] = []
	for node_to_load in current_graph.nodes.values():
		if node_to_load is BehaviorFrame:
			frames.append(node_to_load)
		else:
			load_node(node_to_load)
	for connection in current_graph.connections:
		connect_node(
			connection["from_node"], 
			connection["from_port"], 
			connection["to_node"], 
			connection["to_port"])
	for frame_node in frames:
		load_frame(frame_node)

## Instantiates the visual node for [param node_to_load], restoring its name and position.[br]
## If [param register_in_graph] is [code]true[/code] the [BehaviorNode] is also added to [member current_graph] (used when creating nodes at runtime, e.g. paste/duplicate); when loading an existing graph it is already there.[br]
## Returns the created visual node.
func load_node(node_to_load : BehaviorNode, register_in_graph : bool = false) -> BehaviorGraphNodeBase:
	# Must be set before set_node(): inline editors of blackboard-bound properties read it while being built.
	node_to_load._graph_ref = weakref(current_graph)
	if register_in_graph:
		current_graph.add_node(node_to_load)

	var node: BehaviorGraphNodeBase = _scene_for(node_to_load).instantiate()
	add_child(node)
	node.name = node_to_load.resource_name
	node.graph_edit = self
	node.set_node(node_to_load)
	node.position_offset = node_to_load.position_in_graph
	return node
#endregion

#region Node management

## Adds a new [BehaviorGraphNode], assigns it a [BehaviorNode] script, positions it at the mouse, and registers it in [member current_graph].
func add_node(script_path: String = "") -> BehaviorGraphNodeBase:
	if script_path == "":
		push_error("Script path not valid")
		return null

	var position : Vector2 = (get_local_mouse_position() + scroll_offset) / zoom
	var node_name : StringName = _generate_unique_node_name()
	var node : BehaviorGraphNodeBase = _instantiate_node(load(script_path).new(), position, node_name)

	undo_redo.create_action("Create %s" % node_name, UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_do_create_node", script_path, node_name, position)
	undo_redo.add_undo_method(self, &"_do_remove_node", node_name, node.node)
	undo_redo.commit_action(false) # already performed above; this only records it

	return node

## Shared instantiation step: builds the visual node for [param behavior_node] at [param position],
## optionally forcing its name to [param forced_name] (used so redo recreates the exact same name).
func _instantiate_node(behavior_node: BehaviorNode, position: Vector2, forced_name: StringName = &"") -> BehaviorGraphNodeBase:
	var node: BehaviorGraphNodeBase = _scene_for(behavior_node).instantiate()
	add_child(node)
	if forced_name != &"":
		node.name = forced_name

	node.graph_edit = self
	node.position_offset = position
	behavior_node.position_in_graph = position
	node.set_node(behavior_node) # reads self.name -> writes behavior_node.resource_name

	current_graph.add_node(behavior_node)
	return node

## Redo half of [method add_node].
func _do_create_node(script_path: String, node_name: StringName, position: Vector2) -> void:
	if current_graph.nodes.has(node_name) or has_node(NodePath(node_name)):
		return
	_instantiate_node(load(script_path).new(), position, node_name)

## Undo half of [method add_node] (also reused by delete/paste/embed to remove a single node).
func _do_remove_node(node_name: StringName, behavior_node: BehaviorNode) -> void:
	current_graph.remove_node(behavior_node)
	var el := get_node_or_null(NodePath(node_name))
	if el:
		remove_child(el)
		el.queue_free()

## Disconnects any outgoing connection from [param graph_node] whose port no longer exists after its condition count changed.
func prune_invalid_connections_from(graph_node: BehaviorGraphNodeBase) -> void:
	var n := graph_node.node.conditions.size()
	var max_valid_port : int = 1 + n if n > 0 else 0
	for c in get_connection_list_from_node(graph_node.name):
		if c["from_port"] > max_valid_port:
			disconnect_nodes(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

## Deletes the given nodes/frames as a single undoable action: refuses to delete a graph's last
## remaining starting point, severs every connection touching a deleted node (both directions, and
## only once even if both endpoints are deleted together), and - for a frame - detaches whatever it
## still has attached before removing it. Undo restores everything: the resources themselves are
## kept alive by the arguments below (never duplicated), so identity/data is exact.
func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	var to_delete : Array[StringName] = []
	for n in nodes:
		var element := get_node_or_null(NodePath(n))
		if element is BehaviorGraphFrame:
			to_delete.append(n)
			continue

		var nod := element as BehaviorGraphNodeBase
		if nod == null:
			continue

		if nod.node.is_starting_node and current_graph.get_nodes_by_category("access_point_node").size() <= 1:
			push_error("Node %s cannot be deleted. There must be at least one access point" % n)
			continue

		to_delete.append(n)

	if to_delete.is_empty():
		return

	var deleted_set : Dictionary = {}
	for n in to_delete:
		deleted_set[n] = true

	# Every connection touching at least one deleted (non-frame) node, collected once so a
	# connection between two co-deleted nodes is severed/restored exactly one time.
	var touched_connections : Array[Dictionary] = []
	for c in get_connection_list():
		if deleted_set.has(c["from_node"]) or deleted_set.has(c["to_node"]):
			if c not in touched_connections:
				touched_connections.append(c)

	var frame_snapshots : Dictionary = {} # frame name -> snapshot dict, built below

	var action_name : String = "Delete Node" if to_delete.size() == 1 else "Delete %d Nodes" % to_delete.size()
	undo_redo.create_action(action_name, UndoRedo.MERGE_DISABLE, current_graph)

	undo_redo.add_do_method(self, &"_do_disconnect_many", touched_connections)

	for n in to_delete:
		var element := get_node_or_null(NodePath(n))
		if element is BehaviorGraphFrame:
			var frame := element as BehaviorGraphFrame
			var snapshot : Dictionary = {
				"name": n,
				"resource": frame.frame,
				"title": frame.frame.frame_title,
				"tint_color": frame.frame.tint_color,
				"position": frame.frame.position_in_graph,
				"size": frame.frame.frame_size,
				"autoshrink": frame.frame.autoshrink,
				"attached": get_attached_nodes_of_frame(n).duplicate(),
			}
			frame_snapshots[n] = snapshot
			undo_redo.add_do_method(self, &"_do_remove_frame", snapshot)
		else:
			undo_redo.add_do_method(self, &"_do_remove_node", n, (element as BehaviorGraphNodeBase).node)

	undo_redo.add_do_method(self, &"_sync_frame_attachments")
	undo_redo.add_do_method(self, &"_emit_no_selection")

	# Undo order: a node/frame must exist again before any connection touching it is restored.
	for n in to_delete:
		if frame_snapshots.has(n):
			undo_redo.add_undo_method(self, &"_do_recreate_frame", frame_snapshots[n])
		else:
			var element := get_node_or_null(NodePath(n))
			undo_redo.add_undo_method(self, &"_do_recreate_node", n, (element as BehaviorGraphNodeBase).node)
	undo_redo.add_undo_method(self, &"_do_connect_many", touched_connections)
	undo_redo.add_undo_method(self, &"_sync_frame_attachments")
	undo_redo.add_undo_method(self, &"_emit_no_selection")

	undo_redo.commit_action()

## Emits selected_node_changed(null): a real method (not a closure), required since
## add_do_method/add_undo_method on EditorUndoRedoManager take (object, method_name), never a
## Callable.
func _emit_no_selection() -> void:
	selected_node_changed.emit(null)

func _do_recreate_node(n: StringName, behavior_node: BehaviorNode) -> void:
	if has_node(NodePath(n)):
		return
	load_node(behavior_node, true)

func _do_remove_frame(snapshot: Dictionary) -> void:
	for element_name in get_attached_nodes_of_frame(snapshot["name"]).duplicate():
		detach_graph_element_from_frame(element_name)
	current_graph.remove_node(snapshot["resource"])
	var el := get_node_or_null(NodePath(snapshot["name"]))
	if el:
		remove_child(el)
		el.queue_free()

func _do_recreate_frame(snapshot: Dictionary) -> void:
	if has_node(NodePath(snapshot["name"])):
		return
	var frame_resource : BehaviorFrame = snapshot["resource"]
	frame_resource.frame_title = snapshot["title"]
	frame_resource.tint_color = snapshot["tint_color"]
	frame_resource.position_in_graph = snapshot["position"]
	frame_resource.frame_size = snapshot["size"]
	frame_resource.autoshrink = snapshot["autoshrink"]
	frame_resource.attached_nodes = (snapshot["attached"] as Array).duplicate()
	current_graph.add_node(frame_resource)
	load_frame(frame_resource)
	
## Callback for [signal GraphEdit.node_selected]: forwards the selected node's [BehaviorNode].
func _on_node_selected(node: Node) -> void:
	if node is BehaviorGraphNodeBase:
		selected_node_changed.emit(node.node)

## Callback for [signal GraphEdit.node_deselected]: nothing is selected anymore.
func _on_node_deselected(_node: Node) -> void:
	selected_node_changed.emit(null)
#endregion


#region Connections

## Validates and applies a new connection: no self-connections, one connection per condition, and respects [member BehaviorNode.allows_multiple_outputs]. [br] 
## Updates [member BehaviorNode._next_ref]/[member BehaviorNode.conditions] via [method BehaviorNode.add_next], [member BehaviorGraph.connections], and the visual connection.
func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_node == to_node:
		push_error("Cannot connect a node to itself")
		return

	var f_node: BehaviorGraphNodeBase = get_node(NodePath(from_node))
	var t_node: BehaviorGraphNodeBase = get_node(NodePath(to_node))

	if f_node.node.conditions.size() > 0:
		# Each condition can have only one connection: if this condition already has an exiting connection, deny a new one.
		if is_connection_from_node_from_port_enabled(from_node, from_port):
			push_error("Output %d of node %s is a condition and already has a connection" % [from_port, from_node])
			return
	elif not f_node.node.allows_multiple_outputs:
		# A node that does not have conditions and that allows only one exit: if there's already an exit, deny it.
		if from_node in get_connection_starting_nodes():
			push_error("Node %s does not allow multiple outputs" % from_node)
			return

	var c: Dictionary = {
		"from_node": StringName(from_node.validate_node_name()),
		"from_port": from_port,
		"to_node": StringName(to_node.validate_node_name()),
		"to_port": to_port
	}

	undo_redo.create_action("Connect %s -> %s" % [from_node, to_node], UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_do_connect", c)
	undo_redo.add_undo_method(self, &"_do_disconnect", c)
	undo_redo.commit_action()

## Removes a connection: updates the source [BehaviorNode] via [method BehaviorNode.remove_next], [member BehaviorGraph.connections], and the visual connection.
func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var c: Dictionary = {
		"from_node": from_node,
		"from_port": from_port,
		"to_node": to_node,
		"to_port": to_port
	}
	undo_redo.create_action("Disconnect %s -> %s" % [from_node, to_node], UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_do_disconnect", c)
	undo_redo.add_undo_method(self, &"_do_connect", c)
	undo_redo.commit_action()

## Shared do/undo primitive for a single connection. Reused by connect/disconnect themselves and
## by delete/paste/embed, so there is one source of truth for what "connecting" actually means.
func _do_connect(c: Dictionary) -> void:
	var f_node: BehaviorGraphNodeBase = get_node_or_null(NodePath(c["from_node"]))
	var t_node: BehaviorGraphNodeBase = get_node_or_null(NodePath(c["to_node"]))
	if f_node == null or t_node == null:
		return
	f_node.node.add_next(t_node.node, c["from_port"])
	if c not in current_graph.connections:
		current_graph.add_connection(c)
	connect_node(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

func _do_disconnect(c: Dictionary) -> void:
	var f_node: BehaviorGraphNodeBase = get_node_or_null(NodePath(c["from_node"]))
	var t_node: BehaviorGraphNodeBase = get_node_or_null(NodePath(c["to_node"]))
	if f_node == null or t_node == null:
		return
	f_node.node.remove_next(t_node.node, c["from_port"])
	current_graph.remove_connection(c)
	disconnect_node(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

## Batched variants of _do_connect/_do_disconnect, used wherever several connections must be
## (re)created or severed as part of the same undo/redo step (delete, paste, embed) - one
## add_do_method/add_undo_method call instead of one per connection.
func _do_connect_many(conns: Array[Dictionary]) -> void:
	for c in conns:
		_do_connect(c)

func _do_disconnect_many(conns: Array[Dictionary]) -> void:
	for c in conns:
		_do_disconnect(c)

## Names of every node that is the source of at least one connection.
func get_connection_starting_nodes() -> Array[StringName]:
	var ret: Array[StringName] = []
	for c in connections:
		if c["from_node"] not in ret:
			ret.append(c["from_node"])
	return ret

## Returns [code]true[/code] if [param from_node] already has a connection from [param from_port].
func is_connection_from_node_from_port_enabled(from_node: StringName, from_port: int) -> bool:
	for c in get_connection_list_from_node(from_node):
		if c["from_node"] == from_node and c["from_port"] == from_port:
			return true
	return false

func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2)->void:
	_pending_connection_from = {"from_node": from_node, "from_port": from_port}
	_show_node_creation_popup()

func _complete_pending_connection(new_node: BehaviorGraphNodeBase) -> void:
	if _pending_connection_from.is_empty():
		return

	var from_node: StringName = _pending_connection_from["from_node"]
	var from_port: int = _pending_connection_from["from_port"]
	_pending_connection_from = {}

	if new_node == null or not new_node.node.input:
		return

	connect_nodes(from_node, from_port, new_node.name, 0)
#endregion

#region Node-creation popup
## Builds and opens the node-creation popup at the current mouse position.
func _on_popup_request(at_position: Vector2) -> void:
	_pending_connection_from = {}
	_show_node_creation_popup()

func _show_node_creation_popup() -> void:
	_node_popup = _build_node_popup(NODE_PATH)
	if _node_popup == null:
		_node_popup = PopupMenu.new()
		_node_popup.allow_search = true
		_node_popup.search_bar_enabled = true
		_node_popup.id_pressed.connect(_on_node_popup_id_pressed.bind(_node_popup))

	_append_custom_node_paths(_node_popup)
	add_child(_node_popup)

	_node_popup.popup_hide.connect(_on_node_popup_closed.bind(_node_popup), CONNECT_ONE_SHOT | CONNECT_DEFERRED)

	_node_popup.position = DisplayServer.mouse_get_position()
	_node_popup.popup()

func _on_node_popup_closed(popup: PopupMenu) -> void:
	_pending_connection_from = {}
	if is_instance_valid(popup):
		popup.queue_free()

## Appends custom node paths defined in ProjectSettings ([constant CUSTOM_NODES_PATHS_SETTING])
## as top-level macro-items named after each pointed folder.
func _append_custom_node_paths(root_popup: PopupMenu) -> void:
	if not ProjectSettings.has_setting(CUSTOM_NODES_PATHS_SETTING):
		return
	var setting_val: Variant = ProjectSettings.get_setting(CUSTOM_NODES_PATHS_SETTING)
	var paths: PackedStringArray = []
	if setting_val is PackedStringArray:
		paths = setting_val
	elif setting_val is Array:
		for p in setting_val:
			if p is String:
				paths.append(p)
	elif setting_val is String and not setting_val.is_empty():
		paths.append(setting_val)

	for custom_path in paths:
		var trimmed := custom_path.strip_edges()
		if trimmed.is_empty():
			continue
		if not DirAccess.dir_exists_absolute(trimmed):
			push_warning("Custom node path does not exist: %s" % trimmed)
			continue

		var folder_name := trimmed.trim_suffix("/").get_file()
		if folder_name.is_empty():
			folder_name = trimmed

		var custom_sub := _build_node_popup(trimmed)
		if custom_sub == null:
			continue
		if custom_sub.item_count == 0:
			custom_sub.queue_free()
			continue

		custom_sub.name = folder_name
		root_popup.add_submenu_node_item(folder_name, custom_sub)
		var item_idx := root_popup.item_count - 1
		if Engine.is_editor_hint():
			var theme := EditorInterface.get_editor_theme()
			if theme and theme.has_icon("Folder", "EditorIcons"):
				root_popup.set_item_icon(item_idx, theme.get_icon("Folder", "EditorIcons"))

## Recursively mirrors [param path]'s folder structure into a [PopupMenu]: subfolders become submenus (dropped if empty), [code].gd[/code] files become items labeled via [method _script_metadata]. Returns [code]null[/code] if [param path] doesn't exist.
func _build_node_popup(path: String) -> PopupMenu:
	if not DirAccess.dir_exists_absolute(path):
		push_error("Path not valid: %s" % path)
		return null
	var popup := PopupMenu.new()
	popup.allow_search = true
	popup.search_bar_enabled = true

	var dirs := DirAccess.get_directories_at(path)
	dirs.sort()
	for dir_name in dirs:
		var sub: PopupMenu = _build_node_popup(path.path_join(dir_name))
		if sub == null:
			continue
		if sub.item_count == 0:
			sub.queue_free()
			continue
		sub.name = dir_name

		popup.add_submenu_node_item(dir_name, sub)
		var item_idx := popup.item_count - 1
		if Engine.is_editor_hint():
			var theme := EditorInterface.get_editor_theme()
			if theme and theme.has_icon("Folder", "EditorIcons"):
				popup.set_item_icon(item_idx, theme.get_icon("Folder", "EditorIcons"))

	var files : PackedStringArray = DirAccess.get_files_at(path)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".gd"):
			continue
		var full_path := path.path_join(file_name)
		var id := popup.item_count
		
		var script_metadata = _script_metadata(full_path)
		popup.add_item(script_metadata["label"], id)
		if not script_metadata["icon"] == null:
			popup.set_item_icon(id, script_metadata["icon"])
		popup.set_item_tooltip(id,script_metadata["info"])
		popup.set_item_metadata(id, full_path)

	popup.id_pressed.connect(_on_node_popup_id_pressed.bind(popup))
	return popup

## Creates a node from the script path stored in the selected item's metadata.
func _on_node_popup_id_pressed(id: int, popup: PopupMenu) -> void:
	var script_path = popup.get_item_metadata(id)
	if script_path == null:
		return
	_complete_pending_connection(add_node(script_path))

## Reads a script's [code]DISPLAY_NAME[/code] and [code]DISPLAY_ICON[/code] constants, falling back to its filename and no icon.
func _script_metadata(path: String) -> Dictionary:
	var scr := load(path) as GDScript
	if scr == null:
		return {"label": path.get_file().get_basename(), "icon": null}
	var consts := scr.get_script_constant_map()
	return {
		"label": consts.get("DISPLAY_NAME", path.get_file().get_basename()),
		"icon": load(consts["DISPLAY_ICON"]) if consts.has("DISPLAY_ICON") else null,
		"scene": load(consts["DISPLAY_SCENE"]) if consts.has("DISPLAY_SCENE") else null,
		"info" : consts.get("DISPLAY_INFO","No info has been provided for this node")
	}

func _scene_for(n: BehaviorNode) -> PackedScene:
	var consts: Dictionary = n.get_script().get_script_constant_map()
	if consts.has("DISPLAY_SCENE"):
		return load(consts["DISPLAY_SCENE"])
	return NODE

#region Copy / Paste / Duplicate

## Stores a snapshot of the selected nodes (and of the connections between them) in the clipboard.
func copy_selected_nodes() -> void:
	if current_graph == null:
		return
	var snapshot : Dictionary = _capture_selection()
	if snapshot["nodes"].is_empty():
		return
	_clipboard = snapshot

## Copies the selected nodes, then deletes them.
func _on_cut_nodes_request() -> void:
	copy_selected_nodes()
	var names : Array[StringName] = []
	for graph_node in _get_selected_nodes():
		names.append(graph_node.name)
	if not names.is_empty():
		_on_delete_nodes_request(names)

## Pastes the clipboard with its top-left corner at the mouse (or slightly offset from the originals if the mouse is outside the graph).
func _on_paste_nodes_request() -> void:
	var offset : Vector2 = DUPLICATE_OFFSET
	var mouse : Vector2 = get_local_mouse_position()
	if Rect2(Vector2.ZERO, size).has_point(mouse):
		offset = (mouse + scroll_offset) / zoom - _snapshot_origin(_clipboard)
	_paste_snapshot(_clipboard, offset)

## Duplicates the selected nodes in place (shifted by [constant DUPLICATE_OFFSET]) without touching the clipboard.
func duplicate_selected_nodes() -> void:
	if current_graph == null:
		return
	_paste_snapshot(_capture_selection(), DUPLICATE_OFFSET)

## Builds a snapshot from the current selection: cloned [BehaviorNode]s plus the connections whose both ends are selected.
func _capture_selection() -> Dictionary:
	var nodes : Array[BehaviorNode] = []
	var names : Dictionary = {}
	for graph_node in _get_selected_nodes():
		nodes.append(_clone_behavior_node(graph_node.node))
		names[StringName(graph_node.node.resource_name)] = true

	var connections : Array[Dictionary] = []
	for c in current_graph.connections:
		if names.has(StringName(c["from_node"])) and names.has(StringName(c["to_node"])):
			connections.append(c.duplicate())
	return {"nodes": nodes, "connections": connections}

## Recreates a snapshot inside [member current_graph], as a single undoable action: every node
## gets a fresh unique name; connections between them are rebuilt from scratch. The new nodes end
## up selected.
func _paste_snapshot(snapshot : Dictionary, offset : Vector2) -> void:
	var nodes : Array = snapshot.get("nodes", [])
	if current_graph == null or nodes.is_empty():
		return

	_deselect_all()

	var name_map : Dictionary = {} # old name -> new name
	var copies : Array[BehaviorNode] = []
	for source : BehaviorNode in nodes:
		var copy : BehaviorNode = _clone_behavior_node(source)
		var new_name : StringName = _generate_unique_node_name()
		name_map[StringName(source.resource_name)] = new_name
		copy.resource_name = new_name
		copy.position_in_graph = source.position_in_graph + offset
		_remove_missing_blackboard_bindings(copy)
		copies.append(copy)

	var new_connections : Array[Dictionary] = []
	for c in snapshot["connections"]:
		new_connections.append({
			"from_node": name_map[StringName(c["from_node"])],
			"from_port": c["from_port"],
			"to_node": name_map[StringName(c["to_node"])],
			"to_port": c["to_port"],
		})

	var pasted_names : Array[StringName] = []
	for copy in copies:
		pasted_names.append(StringName(copy.resource_name))

	var action_name : String = "Paste Node" if copies.size() == 1 else "Paste %d Nodes" % copies.size()
	undo_redo.create_action(action_name, UndoRedo.MERGE_DISABLE, current_graph)

	undo_redo.add_do_method(self, &"_do_load_nodes", copies)
	undo_redo.add_do_method(self, &"_do_connect_many", new_connections)
	undo_redo.add_do_method(self, &"_do_select_nodes", pasted_names)

	undo_redo.add_undo_method(self, &"_do_disconnect_many", new_connections)
	undo_redo.add_undo_method(self, &"_do_remove_nodes", copies)

	undo_redo.commit_action()

## Loads every not-yet-present node in [param copies] (shared by paste/duplicate's redo and by
## embed_graph's redo: on first commit the nodes are already loaded live by the caller, so this
## only matters on a later redo).
func _do_load_nodes(copies: Array[BehaviorNode]) -> void:
	for copy in copies:
		if not has_node(NodePath(copy.resource_name)):
			load_node(copy, true)

## Undo counterpart of _do_load_nodes.
func _do_remove_nodes(copies: Array[BehaviorNode]) -> void:
	for copy in copies:
		_do_remove_node(StringName(copy.resource_name), copy)

## Selects every named element (used after a paste/duplicate so the result starts selected).
func _do_select_nodes(names: Array[StringName]) -> void:
	for n in names:
		var el := get_node_or_null(NodePath(n))
		if el:
			el.selected = true

## Recursively searches [param node]'s [Control] descendants for the one whose global rect contains [param global_pos], returning the first (deepest) match found, or [code]null[/code] if none does.
func _generate_unique_node_name(prefix : String = "_GraphNode_") -> StringName:
	var candidate := StringName("%s%d" % [prefix, randi_range(10000, 99999)])
	while current_graph.nodes.has(candidate) or has_node(NodePath(candidate)):
		candidate = StringName("%s%d" % [prefix, randi_range(10000, 99999)])
	return candidate

## Deep-copies [param source] and strips everything tied to the graph it belonged to (successors), so the copy can be wired up from scratch.
func _clone_behavior_node(source : BehaviorNode) -> BehaviorNode:
	var copy : BehaviorNode = source.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as BehaviorNode
	copy._next_ref.clear()
	for condition in copy.conditions:
		condition["next"] = null
	return copy

## Unbinds every property of [param node] linked to a blackboard key that doesn't exist in [member current_graph] (e.g. when pasting into a different graph). The property keeps its last value.
func _remove_missing_blackboard_bindings(node : BehaviorNode) -> void:
	var keys : Array[StringName] = []
	for variable in current_graph.blackboard:
		if variable:
			keys.append(variable.name)
	for prop in node.behavior_properties:
		var key : StringName = node.behavior_properties[prop][&"blackboard_reference"]
		if key != &"" and not keys.has(key):
			node.behavior_properties[prop][&"blackboard_reference"] = &""

## Top-left corner (graph coordinates) of the bounding box of the snapshot's nodes.
func _snapshot_origin(snapshot : Dictionary) -> Vector2:
	var origin := Vector2(INF, INF)
	for n : BehaviorNode in snapshot.get("nodes", []):
		origin.x = minf(origin.x, n.position_in_graph.x)
		origin.y = minf(origin.y, n.position_in_graph.y)
	return origin if origin.is_finite() else Vector2.ZERO

func _get_selected_nodes() -> Array[BehaviorGraphNodeBase]:
	var ret : Array[BehaviorGraphNodeBase] = []
	for child in get_children():
		var graph_node := child as BehaviorGraphNodeBase
		if graph_node != null and graph_node.selected:
			ret.append(graph_node)
	return ret

func _deselect_all() -> void:
	for child in get_children():
		var element := child as GraphElement
		if element != null:
			element.selected = false

#endregion

#region Frames & embedding

## Padding (graph coordinates) between the top-left corner of the embedded nodes and the frame.
const FRAME_PADDING := Vector2(40, 60)

## Copies every node of [param source] (and the connections between them) into [member current_graph], wrapped in a new frame titled after [param source], as a single undoable action. [param source] is never modified.[br]
## Properties bound to a blackboard variable are unbound and reset to the node's default value, since the blackboards of the two graphs are unrelated.[br]
## Access points are skipped unless [param include_access_points] is true, so the embedded flow can be wired to the host graph; frames nested in [param source] are flattened (their nodes are copied, their frames aren't).
func embed_graph(source: BehaviorGraph, include_access_points: bool = false) -> BehaviorGraphFrame:
	if current_graph == null or source == null:
		return null

	var sources : Array[BehaviorNode] = []
	for n in source.nodes.values():
		var src := n as BehaviorNode
		if src == null or src is BehaviorFrame:
			continue
		if src.node_category == "access_point_node" and not include_access_points:
			continue
		sources.append(src)
	if sources.is_empty():
		push_warning("Graph \"%s\" has no nodes to embed" % _graph_display_name(source))
		return null

	# Center the copy in the visible area of the graph.
	var bounds := Rect2(sources[0].position_in_graph, Vector2.ZERO)
	for src in sources:
		bounds = bounds.expand(src.position_in_graph)
	var offset : Vector2 = (scroll_offset + size * 0.5) / zoom - bounds.get_center()

	var name_map : Dictionary = {} # old name -> new name
	var copies : Array[BehaviorNode] = []
	for src in sources:
		var copy : BehaviorNode = _clone_behavior_node(src)
		var new_name : StringName = _generate_unique_node_name()
		name_map[StringName(src.resource_name)] = new_name
		copy.resource_name = new_name
		copy.position_in_graph = src.position_in_graph + offset
		_strip_blackboard_bindings(copy)
		copies.append(copy)

	var new_connections : Array[Dictionary] = []
	for c in source.connections:
		var from_name := StringName(c["from_node"])
		var to_name := StringName(c["to_node"])
		if name_map.has(from_name) and name_map.has(to_name):
			new_connections.append({
				"from_node": name_map[from_name], "from_port": c["from_port"],
				"to_node": name_map[to_name], "to_port": c["to_port"],
			})

	var frame_node := BehaviorFrame.new()
	var frame_name : StringName = _generate_unique_node_name("_GraphFrame_")
	frame_node.resource_name = frame_name
	frame_node.frame_title = _graph_display_name(source)
	frame_node.position_in_graph = bounds.position + offset - FRAME_PADDING
	frame_node.frame_size = bounds.size + Vector2(500, 300)
	for copy in copies:
		frame_node.attached_nodes.append(copy.resource_name)

	# Perform the embed directly (so the frame can be returned synchronously); the action below
	# only records how to undo/redo it, reusing these exact same resource objects.
	for copy in copies:
		load_node(copy, true)
	for c in new_connections:
		_do_connect(c)
	current_graph.add_node(frame_node)
	var frame : BehaviorGraphFrame = load_frame(frame_node)

	undo_redo.create_action("Embed %s" % _graph_display_name(source), UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_do_load_nodes", copies)
	undo_redo.add_do_method(self, &"_do_connect_many", new_connections)
	undo_redo.add_do_method(self, &"_do_add_frame_node", frame_node)

	undo_redo.add_undo_method(self, &"_do_remove_frame_node", frame_node)
	undo_redo.add_undo_method(self, &"_do_disconnect_many", new_connections)
	undo_redo.add_undo_method(self, &"_do_remove_nodes", copies)
	undo_redo.commit_action(false)

	return frame

## Redo half of embed_graph's frame creation: adds frame_node to the graph and creates its visual,
## unless already present (first execution happened live, above).
func _do_add_frame_node(frame_node: BehaviorFrame) -> void:
	if has_node(NodePath(frame_node.resource_name)):
		return
	current_graph.add_node(frame_node)
	load_frame(frame_node)

## Undo half: removes frame_node and its visual (the embedded nodes themselves are removed
## separately by _do_remove_nodes).
func _do_remove_frame_node(frame_node: BehaviorFrame) -> void:
	var fel := get_node_or_null(NodePath(frame_node.resource_name))
	if fel:
		current_graph.remove_node(frame_node)
		remove_child(fel)
		fel.queue_free()

## Creates the visual frame for [param frame_node] (already registered in [member current_graph]) and attaches the nodes it lists.
func load_frame(frame_node: BehaviorFrame) -> BehaviorGraphFrame:
	var frame := BehaviorGraphFrame.new()
	add_child(frame)
	move_child(frame, 0) # keep it behind the nodes
	frame.name = frame_node.resource_name
	frame.set_frame(frame_node, self)

	for element_name in frame_node.attached_nodes:
		var element := get_node_or_null(NodePath(element_name)) as BehaviorGraphNodeBase
		if element == null:
			continue
		attach_graph_element_to_frame(element.name, frame.name)
		frame.track(element)
	if frame_node.autoshrink and not frame_node.attached_nodes.is_empty():
		frame.autoshrink_enabled = true
	_refresh_frame_buttons()
	return frame

## GraphEdit only emits this signal: attaching is up to us.
func _on_elements_linked_to_frame(elements: Array, frame_name: StringName) -> void:
	var frame := get_node_or_null(NodePath(frame_name)) as BehaviorGraphFrame
	if frame == null:
		return

	var previous_frame_of : Dictionary = {} # element name -> old frame name ("" if none)
	var element_names : Array[StringName] = []
	for element_name in elements:
		var element := get_node_or_null(NodePath(element_name)) as BehaviorGraphNodeBase
		if element == null:
			continue
		var old_frame := get_element_frame(element.name) as BehaviorGraphFrame
		previous_frame_of[StringName(element.name)] = StringName(old_frame.name) if old_frame != null else &""
		element_names.append(StringName(element.name))

	if element_names.is_empty():
		return

	_link_elements_to_frame(element_names, frame_name)

	undo_redo.create_action("Attach to Frame", UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_link_elements_to_frame", element_names, frame_name)
	undo_redo.add_undo_method(self, &"_unlink_elements_from_frame", element_names, previous_frame_of)
	undo_redo.commit_action(false)

func _link_elements_to_frame(element_names: Array[StringName], frame_name: StringName) -> void:
	var frame := get_node_or_null(NodePath(frame_name)) as BehaviorGraphFrame
	if frame == null:
		return
	for n in element_names:
		var element := get_node_or_null(NodePath(n)) as GraphElement
		if element == null:
			continue
		var current_frame := get_element_frame(n) as BehaviorGraphFrame
		if current_frame != null and current_frame != frame:
			detach_graph_element_from_frame(n)
			current_frame.untrack(element)
		attach_graph_element_to_frame(n, frame_name)
		frame.track(element)
	_sync_frame_attachments()

func _unlink_elements_from_frame(element_names: Array[StringName], previous_frame_of: Dictionary) -> void:
	for n in element_names:
		var element := get_node_or_null(NodePath(n)) as GraphElement
		if element == null:
			continue
		var current_frame := get_element_frame(n) as BehaviorGraphFrame
		if current_frame != null:
			detach_graph_element_from_frame(n)
			current_frame.untrack(element)
		var old_frame_name : StringName = previous_frame_of[n]
		if old_frame_name != &"":
			var old_frame := get_node_or_null(NodePath(old_frame_name)) as BehaviorGraphFrame
			if old_frame != null:
				attach_graph_element_to_frame(n, old_frame_name)
				old_frame.track(element)
	_sync_frame_attachments()

## Writes the live attachments of every frame back into its [BehaviorFrame], so they get saved with the graph.
func _sync_frame_attachments() -> void:
	for child in get_children():
		var frame := child as BehaviorGraphFrame
		if frame == null or frame.frame == null:
			continue
		var attached : Array[StringName] = []
		for element_name in get_attached_nodes_of_frame(frame.name):
			attached.append(element_name)
		frame.frame.attached_nodes = attached
	_refresh_frame_buttons()

## Unbinds every blackboard-linked property of [param node], restoring the default value of the property (the stored one belongs to the old graph's context).
func _strip_blackboard_bindings(node : BehaviorNode) -> void:
	var defaults : BehaviorNode = null
	for prop in node.behavior_properties:
		if node.behavior_properties[prop][&"blackboard_reference"] == &"":
			continue
		if defaults == null:
			defaults = node.get_script().new()
		node.behavior_properties[prop][&"blackboard_reference"] = &""

func _graph_display_name(graph: BehaviorGraph) -> String:
	if graph.resource_name != "":
		return graph.resource_name
	if graph.resource_path != "":
		return graph.resource_path.get_file().get_basename()
	return "Embedded Graph"

## Creates a new frame around the currently selected nodes, as a single undoable action. Nodes
## that already belong to another frame are moved to the new one (an element can only be in one
## frame). Returns the new frame, or [code]null[/code] if nothing is selected.
func create_frame_from_selection(frame_title: String = "Frame") -> BehaviorGraphFrame:
	if current_graph == null:
		return null
	var selected : Array[BehaviorGraphNodeBase] = _get_selected_nodes()
	if selected.is_empty():
		push_warning("Select at least one node to create a frame")
		return null

	# Bounding box of the real on-screen rectangles of the selected nodes.
	var bounds := Rect2(selected[0].position_offset, selected[0].size)
	for graph_node in selected:
		bounds = bounds.merge(Rect2(graph_node.position_offset, graph_node.size))

	var frame_node := BehaviorFrame.new()
	var frame_name : StringName = _generate_unique_node_name("_GraphFrame_")
	frame_node.resource_name = frame_name
	frame_node.frame_title = frame_title
	frame_node.position_in_graph = bounds.position - FRAME_PADDING
	frame_node.frame_size = bounds.size + FRAME_PADDING * 2.0

	# Node (by name) -> the frame it is leaving ("" if none), so undo can put it back there.
	var previous_frame_of : Dictionary = {}
	var node_names : Array[StringName] = []
	for graph_node in selected:
		var old_frame := get_element_frame(graph_node.name) as BehaviorGraphFrame
		var n : StringName = StringName(graph_node.name)
		previous_frame_of[n] = StringName(old_frame.name) if old_frame != null else &""
		node_names.append(n)
		frame_node.attached_nodes.append(n)

	_attach_frame_selection(frame_node, node_names, previous_frame_of, true)
	var frame : BehaviorGraphFrame = get_node(NodePath(frame_name))

	undo_redo.create_action("Create Frame", UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_attach_frame_selection", frame_node, node_names, previous_frame_of, false)
	undo_redo.add_undo_method(self, &"_detach_frame_selection", frame_name, frame_node, node_names, previous_frame_of)
	undo_redo.commit_action(false)

	return frame

## Shared do/redo step: detaches [param node_names] from whatever frame they were previously in
## (per [param previous_frame_of]), then creates [param frame_node]'s visual (which attaches them,
## since load_frame reads frame_node.attached_nodes - already populated once, up front).
func _attach_frame_selection(frame_node: BehaviorFrame, node_names: Array[StringName], previous_frame_of: Dictionary, focus_title_on_create: bool) -> void:
	if has_node(NodePath(frame_node.resource_name)):
		return
	for n in node_names:
		var old_frame_name : StringName = previous_frame_of[n]
		if old_frame_name != &"":
			var old_frame := get_node_or_null(NodePath(old_frame_name)) as BehaviorGraphFrame
			var el := get_node_or_null(NodePath(n)) as GraphElement
			if old_frame != null and el != null:
				detach_graph_element_from_frame(n)
				old_frame.untrack(el)
	current_graph.add_node(frame_node)
	var frame := load_frame(frame_node)
	_sync_frame_attachments()
	if focus_title_on_create:
		frame.focus_title()

## Undo step: removes the frame and puts each node back into whatever frame (if any) it came from.
func _detach_frame_selection(frame_name: StringName, frame_node: BehaviorFrame, node_names: Array[StringName], previous_frame_of: Dictionary) -> void:
	var fel := get_node_or_null(NodePath(frame_name)) as BehaviorGraphFrame
	if fel == null:
		return
	for element_name in get_attached_nodes_of_frame(frame_name).duplicate():
		detach_graph_element_from_frame(element_name)
	current_graph.remove_node(frame_node)
	remove_child(fel)
	fel.queue_free()

	for n in node_names:
		var old_frame_name : StringName = previous_frame_of[n]
		if old_frame_name != &"":
			var old_frame := get_node_or_null(NodePath(old_frame_name)) as BehaviorGraphFrame
			var el := get_node_or_null(NodePath(n)) as GraphElement
			if old_frame != null and el != null:
				attach_graph_element_to_frame(n, old_frame_name)
				old_frame.track(el)
	_sync_frame_attachments()

## Detaches every selected node from the frame it belongs to, as a single undoable action. The
## nodes stay where they are and the frame keeps its other nodes.
func detach_selected_nodes_from_frame() -> void:
	if current_graph == null:
		return
	var names : Array[StringName] = []
	for graph_node in _get_selected_nodes():
		names.append(StringName(graph_node.name))
	_detach_names_from_frame(names)

## Detaches a single node from its frame (used by the node's own "free from frame" button).
func detach_node_from_frame(element_name: StringName) -> void:
	if current_graph == null:
		return
	_detach_names_from_frame([StringName(element_name)])

## Shared by both entry points above: detaches every name in [param names] currently in a frame,
## as a single undoable action.
func _detach_names_from_frame(names: Array[StringName]) -> void:
	var previous_frame_of : Dictionary = {} # element name -> old frame name
	for n in names:
		var frame := get_element_frame(n) as BehaviorGraphFrame
		if frame != null:
			previous_frame_of[n] = StringName(frame.name)
	if previous_frame_of.is_empty():
		return

	_do_detach_names(previous_frame_of)

	undo_redo.create_action("Detach From Frame", UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_do_detach_names", previous_frame_of)
	undo_redo.add_undo_method(self, &"_do_reattach_names", previous_frame_of)
	undo_redo.commit_action(false)

func _do_detach_names(previous_frame_of: Dictionary) -> void:
	for n in previous_frame_of:
		var frame := get_node_or_null(NodePath(previous_frame_of[n])) as BehaviorGraphFrame
		var element := get_node_or_null(NodePath(n)) as GraphElement
		if frame != null and element != null and get_element_frame(n) == frame:
			detach_graph_element_from_frame(n)
			frame.untrack(element)
	_sync_frame_attachments()

func _do_reattach_names(previous_frame_of: Dictionary) -> void:
	for n in previous_frame_of:
		var frame := get_node_or_null(NodePath(previous_frame_of[n])) as BehaviorGraphFrame
		var element := get_node_or_null(NodePath(n)) as GraphElement
		if frame != null and element != null:
			attach_graph_element_to_frame(n, previous_frame_of[n])
			frame.track(element)
	_sync_frame_attachments()

## Shows the "free from frame" button only on the nodes that currently belong to a frame.
func _refresh_frame_buttons() -> void:
	for child in get_children():
		var graph_node := child as BehaviorGraphNodeBase
		if graph_node != null:
			graph_node.set_framed(get_element_frame(graph_node.name) != null)

#endregion

#region Move tracking

## Positions of every selected element (name -> position_offset) captured at the start of a drag,
## used by _on_end_node_move to build a single undoable "move" action.
var _move_start_positions : Dictionary = {}

func _on_begin_node_move() -> void:
	_move_start_positions.clear()
	for child in get_children():
		var element := child as GraphElement
		if element != null and element.selected:
			_move_start_positions[StringName(element.name)] = element.position_offset

func _on_end_node_move() -> void:
	var start : Dictionary = _move_start_positions
	_move_start_positions = {}
	if start.is_empty():
		return

	var end : Dictionary = {}
	var moved : bool = false
	for n in start:
		var element := get_node_or_null(NodePath(n)) as GraphElement
		if element == null:
			continue
		end[n] = element.position_offset
		if not (end[n] as Vector2).is_equal_approx(start[n]):
			moved = true
	if not moved:
		return

	undo_redo.create_action("Move", UndoRedo.MERGE_DISABLE, current_graph)
	undo_redo.add_do_method(self, &"_apply_positions", end)
	undo_redo.add_undo_method(self, &"_apply_positions", start)
	undo_redo.commit_action(false) # the drag already moved them; this just records it

## Applies a name -> position_offset map. Relies on position_offset_changed (already connected in
## BehaviorGraphNodeBase/BehaviorGraphFrame) to keep node.position_in_graph / frame.position_in_graph
## in sync - nothing else needs touching here.
func _apply_positions(positions: Dictionary) -> void:
	for n in positions:
		var element := get_node_or_null(NodePath(n)) as GraphElement
		if element == null:
			continue
		element.position_offset = positions[n]

#endregion
