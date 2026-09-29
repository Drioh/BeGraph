@tool
## A [GraphEdit] that visually builds and edits a [BehaviorGraph]: creates nodes from a categorized popup (built from [constant NODE_PATH]), handles connecting/disconnecting them, and keeps the underlying [BehaviorNode] resources in sync with the visual graph.
class_name BehaviorGraphEdit
extends GraphEdit

#region Constants

## Root directory scanned for node scripts to populate the creation popup. Subdirectories become submenus.
const NODE_PATH = "res://addons/BeGraph/Classes/Nodes/"

## Scene instantiated for each new [BehaviorGraphNode].
const NODE = preload("res://addons/BeGraph/UI/BehaviorGraphNode.tscn")

#endregion

#region State

## The [BehaviorGraph] currently being edited.
var current_graph: BehaviorGraph

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
#endregion


#region Graph loading

## Clears the current visual graph (connections and [BehaviorGraphNode] children), loads [param graph] as [member current_graph], and rebuilds it via [method load_nodes] and [method load_connections].
func set_graph(graph: BehaviorGraph) -> void:
	current_graph = null
	selected_node_changed.emit(null)

	if connections.size() > 0:
		clear_connections()

	for child in get_children().duplicate():
		if child is not BehaviorGraphNodeBase:
			continue
		remove_child(child)
		child.free()
	current_graph = graph

	for node_to_load in current_graph.nodes.values():
		load_node(node_to_load)
	for connection in current_graph.connections:
		connect_node(
			connection["from_node"], 
			connection["from_port"], 
			connection["to_node"], 
			connection["to_port"])

## Instantiates a [BehaviorGraphNode], restoring its name, position, and delete handling.
func load_node(node_to_load : BehaviorNode) -> void:
	var node: BehaviorGraphNodeBase = _scene_for(node_to_load).instantiate()
	add_child(node)
	node.name = node_to_load.resource_name
	node.graph_edit = self
	node.set_node(node_to_load)
	node.node._graph_ref = weakref(current_graph)
	node.position_offset = node_to_load.position_in_graph
#endregion

#region Node management

## Adds a new [BehaviorGraphNode], assigns it a [BehaviorNode] script, positions it at the mouse, and registers it in [member current_graph].
func add_node(script_path: String = "") -> BehaviorGraphNodeBase:
	if script_path == "":
		push_error("Script path not valid")
		return null

	var behavior_node: BehaviorNode = load(script_path).new()

	var node: BehaviorGraphNodeBase = _scene_for(behavior_node).instantiate()
	add_child(node)

	node.graph_edit = self
	node.position_offset = (get_local_mouse_position() + scroll_offset) / zoom
	behavior_node.position_in_graph = node.position_offset
	node.set_node(behavior_node)
	node.delete_request.connect(_on_delete_nodes_request)

	current_graph.add_node(behavior_node)
	return node

## Disconnects any outgoing connection from [param graph_node] whose port no longer exists after its condition count changed.
func prune_invalid_connections_from(graph_node: BehaviorGraphNodeBase) -> void:
	var n := graph_node.node.conditions.size()
	var max_valid_port : int = 1 + n if n > 0 else 0
	for c in get_connection_list_from_node(graph_node.name):
		if c["from_port"] > max_valid_port:
			disconnect_nodes(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

## Deletes the given nodes, refusing to delete a graph's last remaining starting point; also removes their connections - both outgoing and incoming (properly updating the surviving neighbor's [BehaviorNode] via [method BehaviorNode.remove_next], so a condition/[member BehaviorNode._next_ref] entry pointing at a deleted node never lingers) - and hands the inspector back to [member current_graph] if needed.[br]
func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for n in nodes:
		var nod = get_node(NodePath(n)) as BehaviorGraphNodeBase

		if nod.node.is_starting_node and current_graph.get_nodes_by_category("access_point_node").size() == 1:
			push_error("node %s cannot ben deleted. There must be at least one access point" % nod)
			return

		# Outgoing connections: nod.node itself is being discarded, so there's no need to
		# call remove_next() on it - only the visual/graph-level bookkeeping matters here.
		for c in get_connection_list_from_node(n):
			disconnect_node(
				c["from_node"].validate_node_name(), 
				c["from_port"], 
				c["to_node"].validate_node_name(), 
				c["to_port"])
			current_graph.remove_connection({
				"from_node": StringName(c["from_node"].validate_node_name()),
				"from_port": c["from_port"],
				"to_node": StringName(c["to_node"].validate_node_name()),
				"to_port": c["to_port"]
			})

		# Incoming connections: the source node survives, so its BehaviorNode must be told
		# (via remove_next) that this successor no longer exists, and its port color refreshed.
		for c in get_connection_list():
			var to_name: StringName = StringName(c["to_node"].validate_node_name())
			var from_name: StringName = StringName(c["from_node"].validate_node_name())
			if not has_node(NodePath(from_name)) or to_name != n:
				continue
			var f_node: BehaviorGraphNodeBase = get_node(NodePath(from_name))

			f_node.node.remove_next(nod.node, c["from_port"])
			disconnect_node(from_name, c["from_port"], to_name, c["to_port"])
			current_graph.remove_connection({
				"from_node": from_name,
				"from_port": c["from_port"],
				"to_node": to_name,
				"to_port": c["to_port"]
			})
			f_node.refresh_port_colors()

		current_graph.remove_node(nod.node)
		remove_child(nod)
	selected_node_changed.emit(null)
	
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
	f_node.node.add_next(t_node.node, from_port)
	if c not in current_graph.connections:
		current_graph.add_connection(c)

	connect_node(from_node, from_port, to_node, to_port)

## Removes a connection: updates the source [BehaviorNode] via [method BehaviorNode.remove_next], [member BehaviorGraph.connections], and the visual connection.
func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var f_node: BehaviorGraphNodeBase = get_node(NodePath(from_node))
	var t_node: BehaviorGraphNodeBase = get_node(NodePath(to_node))

	var c: Dictionary = {
		"from_node": from_node,
		"from_port": from_port,
		"to_node": to_node,
		"to_port": to_port
	}

	f_node.node.remove_next(t_node.node, from_port)
	current_graph.remove_connection(c)

	disconnect_node(from_node, from_port, to_node, to_port)

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
	add_child(_node_popup)

	_node_popup.popup_hide.connect(_on_node_popup_closed.bind(_node_popup), CONNECT_ONE_SHOT | CONNECT_DEFERRED)

	_node_popup.position = DisplayServer.mouse_get_position()
	_node_popup.popup()

func _on_node_popup_closed(popup: PopupMenu) -> void:
	_pending_connection_from = {}
	if is_instance_valid(popup):
		popup.queue_free()
## Recursively mirrors [param path]'s folder structure into a [PopupMenu]: subfolders become submenus (dropped if empty), [code].gd[/code] files become items labeled via [method _script_metadata]. Returns [code]null[/code] if [param path] doesn't exist.
func _build_node_popup(path: String) -> PopupMenu:
	if not DirAccess.dir_exists_absolute(path):
		push_error("Path not valid: %s" % path)
		return null
	var popup := PopupMenu.new()
	popup.allow_search=true
	popup.search_bar_enabled=true

	var dirs := DirAccess.get_directories_at(path)
	dirs.sort()
	for dir_name in dirs:
		var sub :PopupMenu= _build_node_popup(path.path_join(dir_name))
		if sub.item_count == 0:
			sub.queue_free()
			continue
		sub.name = dir_name

		popup.add_submenu_node_item(dir_name, sub)
		popup.set_item_icon(-1, EditorInterface.get_editor_theme().get_icon("Folder", "EditorIcons"))

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
