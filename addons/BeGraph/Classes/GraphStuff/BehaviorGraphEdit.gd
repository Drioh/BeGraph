@tool
## A [GraphEdit] that visually builds and edits a [BehaviorGraph]: creates nodes from a categorized popup (built from [constant NODE_PATH]), handles connecting/disconnecting them, and keeps the underlying [BehaviorNode] resources in sync with the visual graph.
class_name BehaviorGraphEdit
extends GraphEdit

#region Constants

## Root directory scanned for node scripts to populate the creation popup. Subdirectories become submenus.
const NODE_PATH = "res://addons/BeGraph/Classes/Nodes/"

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
		var element := get_node_or_null(NodePath(n))
		if element is BehaviorGraphFrame:
			_delete_frame(element)
			continue

		var nod := element as BehaviorGraphNodeBase
		if nod == null:
			continue

		if nod.node.is_starting_node and current_graph.get_nodes_by_category("access_point_node").size() <= 1:
			push_error("Node %s cannot be deleted. There must be at least one access point" % n)
			continue

		for c in get_connection_list():
			if c["from_node"] == n or c["to_node"] == n:
				disconnect_nodes(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

		current_graph.remove_node(nod.node)
		remove_child(nod)
		nod.queue_free()
	_sync_frame_attachments()
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

## Recreates a snapshot inside [member current_graph]: every node gets a fresh unique name and is created through [method load_node]; connections between them are then rebuilt through [method connect_nodes]. The new nodes end up selected.
func _paste_snapshot(snapshot : Dictionary, offset : Vector2) -> void:
	var nodes : Array = snapshot.get("nodes", [])
	if current_graph == null or nodes.is_empty():
		return

	_deselect_all()

	var name_map : Dictionary = {} # old name -> new name
	var created : Array[BehaviorGraphNodeBase] = []
	for source : BehaviorNode in nodes:
		var copy : BehaviorNode = _clone_behavior_node(source)
		var new_name : StringName = _generate_unique_node_name()
		name_map[StringName(source.resource_name)] = new_name
		copy.resource_name = new_name
		copy.position_in_graph = source.position_in_graph + offset
		_remove_missing_blackboard_bindings(copy)
		created.append(load_node(copy, true))

	for c in snapshot["connections"]:
		connect_nodes(
			name_map[StringName(c["from_node"])], c["from_port"],
			name_map[StringName(c["to_node"])], c["to_port"])

	for graph_node in created:
		graph_node.selected = true

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
		var key : StringName = prop["blackboard_key"]
		if key != &"" and not keys.has(key):
			prop["blackboard_key"] = &""

## Returns a node name (same style as the auto-generated ones) not used by any node in the graph or any child of this GraphEdit.
func _generate_unique_node_name(prefix : String = "_GraphNode_") -> StringName:
	var candidate := StringName("%s%d" % [prefix, randi_range(10000, 99999)])
	while current_graph.nodes.has(candidate) or has_node(NodePath(candidate)):
		candidate = StringName("%s%d" % [prefix, randi_range(10000, 99999)])
	return candidate

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

## Copies every node of [param source] (and the connections between them) into [member current_graph], wrapped in a new frame titled after [param source]. [param source] is never modified.[br]
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
	var created : Array[BehaviorGraphNodeBase] = []
	for src in sources:
		var copy : BehaviorNode = _clone_behavior_node(src)
		var new_name : StringName = _generate_unique_node_name()
		name_map[StringName(src.resource_name)] = new_name
		copy.resource_name = new_name
		copy.position_in_graph = src.position_in_graph + offset
		_strip_blackboard_bindings(copy)
		created.append(load_node(copy, true))

	for c in source.connections:
		var from_name := StringName(c["from_node"])
		var to_name := StringName(c["to_node"])
		if name_map.has(from_name) and name_map.has(to_name):
			connect_nodes(name_map[from_name], c["from_port"], name_map[to_name], c["to_port"])

	var frame_node := BehaviorFrame.new()
	frame_node.resource_name = _generate_unique_node_name("_GraphFrame_")
	frame_node.frame_title = _graph_display_name(source)
	frame_node.position_in_graph = bounds.position + offset - FRAME_PADDING
	frame_node.frame_size = bounds.size + Vector2(500, 300)
	for graph_node in created:
		frame_node.attached_nodes.append(graph_node.name)
	current_graph.add_node(frame_node)
	return load_frame(frame_node)

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
	return frame

## GraphEdit only emits this signal: attaching is up to us.
func _on_elements_linked_to_frame(elements: Array, frame_name: StringName) -> void:
	var frame := get_node_or_null(NodePath(frame_name)) as BehaviorGraphFrame
	if frame == null:
		return
	for element_name in elements:
		var element := get_node_or_null(NodePath(element_name)) as BehaviorGraphNodeBase
		if element == null:
			continue
		attach_graph_element_to_frame(element.name, frame_name)
		frame.track(element)
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

## Removes only the frame: its nodes stay in the graph.
func _delete_frame(frame: BehaviorGraphFrame) -> void:
	for element_name in get_attached_nodes_of_frame(frame.name):
		detach_graph_element_from_frame(element_name)
	current_graph.remove_node(frame.frame)
	remove_child(frame)
	frame.queue_free()

## Unbinds every blackboard-linked property of [param node], restoring the default value of the property (the stored one belongs to the old graph's context).
func _strip_blackboard_bindings(node : BehaviorNode) -> void:
	var defaults : BehaviorNode = null
	for prop in node.behavior_properties:
		if prop["blackboard_key"] == &"":
			continue
		if defaults == null:
			defaults = node.get_script().new()
		prop["blackboard_key"] = &""
		for default_prop in defaults.behavior_properties:
			if default_prop["name"] == prop["name"]:
				prop["value"] = default_prop["value"]
				break

func _graph_display_name(graph: BehaviorGraph) -> String:
	if graph.resource_name != "":
		return graph.resource_name
	if graph.resource_path != "":
		return graph.resource_path.get_file().get_basename()
	return "Embedded Graph"

#endregion
