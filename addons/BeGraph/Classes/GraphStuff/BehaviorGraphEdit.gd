@tool
## A [GraphEdit] used to visually build and edit a [BehaviorGraph].[br]
## Handles node creation (via a categorized popup menu built from the files found
## in [constant NODE_PATH]), connecting/disconnecting nodes, and keeping the
## underlying [BehaviorNode] resources in sync with the visual graph connections.
class_name BehaviorGraphEdit
extends GraphEdit

## Root directory scanned for available node scripts (.gd files), used to build
## the node-creation popup menu. Subdirectories become submenus.
const NODE_PATH = "res://addons/BeGraph/Classes/Nodes/"
## Scene used to instantiate a new [BehaviorGraphNode] visual node.
const NODE = preload("res://addons/BeGraph/UI/BehaviorGraphNode.tscn")

## The [BehaviorGraph] resource currently being edited by this graph.
var current_graph: BehaviorGraph
## [BehaviorGraphBlackboard] containing variables local to [member current_graph].
var local_blackboard : BehaviorGraphBlackboard 
## [BehaviorGraphBlackboard] containing variables shared across multiple graphs.
var shared_blackboard : BehaviorGraphBlackboard 

## Root [PopupMenu] shown when the user requests to create a new node
## (built dynamically from [constant NODE_PATH]).
var _node_popup: PopupMenu

## Button used to print debug information about every node in the graph.
@onready var info_button: Button = %InfoButton

## Label displaying the name/path of the currently loaded [BehaviorGraph].
@onready var graph_label: Label = %GraphLabel

func _ready() -> void:
	delete_nodes_request.connect(_on_delete_nodes_request)
	connection_request.connect(connect_nodes)
	disconnection_request.connect(disconnect_nodes)
	popup_request.connect(_on_popup_request)

## Callback for [signal GraphEdit.connection_request]. Validates the connection
## (no self-connections, and respects [member BehaviorNode.allows_multiple_outputs]),
## then updates both the underlying [BehaviorNode.next] array and the visual
## connection between the two [BehaviorGraphNode]s.
func connect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	if from_node == to_node:
		push_error("Cannot connect a node to itself")
		return
	
	var f_node : BehaviorGraphNode = get_node(NodePath(from_node))
	var t_node : BehaviorGraphNode = get_node(NodePath(to_node))
	
	var cond_1 : bool = from_node in get_connection_starting_nodes()
	var cond_2 : bool = not f_node.node.allows_multiple_outputs
	var cond_3 : bool = get_connection_count(from_node,from_port)>0
	if  cond_1 and cond_2 and cond_3:
		push_error("Node %s does not allow multiple outputs"%from_node)
		return
	f_node.node.add_next(t_node.node)
	var c:Dictionary = {
		"from_node":from_node,
		"from_port":from_port,
		"to_node":to_node,
		"to_port":to_port
	}
	current_graph.add_connection(c)
	connect_node(from_node,from_port,to_node,to_port)

## Callback for [signal GraphEdit.disconnection_request]. Removes the successor
## reference from the source [BehaviorNode.next] array (if present) and removes
## the visual connection between the two [BehaviorGraphNode]s.
func disconnect_nodes(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	var f_node : BehaviorGraphNode = get_node(NodePath(from_node))
	var t_node : BehaviorGraphNode = get_node(NodePath(to_node))
	
	if f_node.node.next.has(t_node.node):
		f_node.node.next.erase(t_node.node)
	var c:Dictionary = {
		"from_node":from_node,
		"from_port":from_port,
		"to_node":to_node,
		"to_port":to_port
	}
	current_graph.remove_connection(c)
	disconnect_node(from_node,from_port,to_node,to_port)

## Loads the given [BehaviorGraph] into the editor: stores the reference,
## updates [member graph_label] with its name/path, and caches its local and
## shared blackboards for use by child node editors.
func set_graph(graph: BehaviorGraph) -> void:
	current_graph=null
	
	if connections.size()>0:
		clear_connections()
	
	for child in get_children().duplicate():
		if child is BehaviorGraphNode:
			child.queue_free()
	current_graph = graph
	
	local_blackboard=current_graph.local_blackboard
	shared_blackboard=current_graph.shared_blackboard
	
	for node in current_graph.nodes:
		load_node(node)
	for connection in current_graph.connections:
		connect_node(connection["from_node"],connection["from_port"],connection["to_node"],connection["to_port"])
## Instantiates a new [BehaviorGraphNode] visual node, adds it as a child of
## this graph, and, if [param script_path] is provided, assigns it the
## [BehaviorNode] script found at that path.
func add_node(script_path: String = "") -> void:
	var node : BehaviorGraphNode = NODE.instantiate()
	add_child(node)
	node.graph_edit = self
	if script_path != "":
		node.set_node_script(script_path)
		
		node.position_offset = (get_local_mouse_position() + scroll_offset) / zoom
		node.node.position_in_graph = node.position_offset
		node.node.resource_name = node.name
		current_graph.add_node(node.node)
		
		node.delete_request.connect(_on_delete_nodes_request)
	
func load_node(n:BehaviorNode):
	var node : BehaviorGraphNode = NODE.instantiate()
	add_child(node)
	node.graph_edit = self
	node.set_node(n)
	node.position_offset = n.position_in_graph
	node.name=n.resource_name
	node.delete_request.connect(_on_delete_nodes_request)
	
## Callback for [signal GraphEdit.delete_nodes_request]. Removes each requested
## node (identified by [StringName]) from the graph, provided
## [member BehaviorGraphNode.can_be_deleted] is [code]true[/code] for all of
## them; also removes any connections attached to a deleted node and, if the
## node being deleted is currently inspected, switches the inspector back to
## [member current_graph].
func _on_delete_nodes_request(nodes: Array[StringName]):
	for n in nodes:
		var nod = get_node(NodePath(n)) as BehaviorGraphNode
		
		if nod.node.is_starting_node && current_graph.get_starting_nodes().size()==1:
			push_error("node %s cannot ben deleted. There must be at least one access point" % nod)
			return
		for c in get_connection_list_from_node(n):
			disconnect_node(c["from_node"],c["from_port"],c["to_node"],c["to_port"])
			current_graph.remove_connection(
				{"from_node":c["from_node"],
				"from_port":c["from_port"],
				"to_node":c["to_node"],
				"to_port":c["to_port"]}
			)
		if EditorInterface.get_inspector().get_edited_object() == nod.node:
			EditorInterface.inspect_object(current_graph)
		current_graph.remove_node(nod.node)
		remove_child(nod)
		
## Callback for [signal GraphEdit.popup_request]. Builds the node-creation
## popup menu (from [constant NODE_PATH]) and displays it at the current mouse
## position.
func _on_popup_request(at_position: Vector2) -> void:
	_node_popup = _build_node_popup(NODE_PATH)
	add_child(_node_popup)
	
	_node_popup.position = DisplayServer.mouse_get_position()
	_node_popup.popup()

## Recursively builds a [PopupMenu] mirroring the directory structure found at
## [param path]: subdirectories become nested submenus (only included if they
## contain at least one valid entry), and each [code].gd[/code] file becomes a
## selectable item labeled via [method _label_for_script]. Returns [code]null[/code]
## if [param path] does not exist.
func _build_node_popup(path: String) -> PopupMenu:
	if not DirAccess.dir_exists_absolute(path):
		push_error("Path not valid: %s" % path)
		return null

	var popup := PopupMenu.new()

	var dirs := DirAccess.get_directories_at(path)
	dirs.sort()
	for dir_name in dirs:
		var sub := _build_node_popup(path.path_join(dir_name))
		if sub == null or sub.item_count == 0:
			if sub: sub.queue_free()
			continue
		sub.name = dir_name
		sub.set_item_icon(-1,EditorInterface.get_editor_theme().get_icon("Folder", "EditorIcons"))
		
		popup.add_child(sub)
		popup.add_submenu_node_item(dir_name, sub)
		
	var files := DirAccess.get_files_at(path)
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".gd"):
			continue
		var full_path := path.path_join(file_name)
		var id := popup.item_count
		popup.add_item(_label_for_script(full_path), id)
		popup.set_item_metadata(id, full_path)
		
	popup.id_pressed.connect(_on_node_popup_id_pressed.bind(popup))
	return popup

## Callback fired when an item in the node-creation popup is selected; creates
## a new node using the script path stored in the item's metadata.
func _on_node_popup_id_pressed(id: int, popup: PopupMenu) -> void:
	var script_path = popup.get_item_metadata(id)
	if script_path != null:
		add_node(script_path)

## Returns the display label for the script at [param script_path]: uses its
## [code]DISPLAY_NAME[/code] constant if defined and non-empty, otherwise falls
## back to the file's base name.
func _label_for_script(script_path: String) -> String:
	var scr := load(script_path) as GDScript
	if scr == null:
		return script_path.get_file().get_basename()
	var consts := scr.get_script_constant_map()
	if consts.has("DISPLAY_NAME") and consts["DISPLAY_NAME"] != "":
		return consts["DISPLAY_NAME"]
	return script_path.get_file().get_basename()

## Returns the [StringName] of every node in the graph that is the source
## ("from") end of at least one connection.
func get_connection_starting_nodes()->Array[StringName]:
	var ret : Array[StringName] = []
	for c in connections:
		if c["from_node"] not in ret: ret.append(c["from_node"])
	return ret

## Returns the [StringName] of every node in the graph that is the destination
## ("to") end of at least one connection.
func get_connection_ending_nodes()->Array[StringName]:
	var ret : Array[StringName] = []
	for c in connections:
		if c["to_node"] not in ret: ret.append(c["to_node"])
	return ret
