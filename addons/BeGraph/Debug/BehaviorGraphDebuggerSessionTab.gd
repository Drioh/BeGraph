@tool
## Root script of [code]BehaviorGraphDebuggerSessionTab.tscn[/code]: the "BeGraph" tab shown in the editor's Debugger panel for one running game session (see [BehaviorGraphDebuggerPlugin]). Kept as a scene rather than built in code so its layout can be tweaked directly in the editor; this script only exposes its controls via unique names, exactly like [code]BeGraphDock.gd[/code] does for the main dock.
class_name BehaviorGraphDebuggerSessionTab
extends VBoxContainer

## Lets the person pick which running [BehaviorAgent] to inspect.
@onready var agent_option : OptionButton = %AgentOption
@onready var agent_label: Label = %AgentLabel
@onready var running_label: Label = %RunningLabel
## Renders the selected agent's graph, live.
@onready var debug_view : BehaviorGraphDebugView = %DebugView

## Shows/hides [member blackboard_panel].
@onready var blackboard_toggle : Button = %BlackboardToggle
## Toggleable side panel listing the selected agent's blackboard variables.
@onready var blackboard_panel : PanelContainer = %BlackboardPanel
## Table of blackboard variables: column 0 is the value's type (as an icon), column 1 its name, column 2 its current value.
@onready var blackboard_tree : Tree = %BlackboardTree

## Variable name (String) -> the row ([TreeItem]) showing it in [member blackboard_tree], so [method apply_blackboard_delta] can update a row in place instead of rebuilding the whole tree.
var _blackboard_rows : Dictionary = {}

func _ready() -> void:
	blackboard_toggle.toggled.connect(func(pressed: bool): 
		blackboard_panel.visible = pressed
		blackboard_toggle.text = "Hide Blackboard" if pressed else "Show Blackboard"
		)
	blackboard_panel.visible = blackboard_toggle.button_pressed
	_setup_blackboard_tree()

func _setup_blackboard_tree() -> void:
	blackboard_tree.columns = 2
	blackboard_tree.hide_root = true
	blackboard_tree.column_titles_visible = true
	blackboard_tree.set_column_title(0, "Name")
	blackboard_tree.set_column_title(1, "Value")
	blackboard_tree.set_column_expand(0, true)
	blackboard_tree.set_column_expand_ratio(0,1)
	blackboard_tree.set_column_expand_ratio(1,3)
	blackboard_tree.set_column_custom_minimum_width(0, 28)
	blackboard_tree.set_column_expand(1, true)
	blackboard_tree.create_item()

## Fully rebuilds [member blackboard_tree] from [param blackboard] - a [code]{variable name (String): [type:int, value]}[/code] Dictionary, the shape [BehaviorGraphDebuggerPlugin] caches per agent. Called whenever the selected agent changes (or its graph gets (re)announced).
func set_blackboard(blackboard: Dictionary) -> void:
	_blackboard_rows.clear()
	blackboard_tree.clear()
	var root := blackboard_tree.create_item()
	for var_name in blackboard:
		_add_blackboard_row(root, var_name, blackboard[var_name][0], blackboard[var_name][1])

## Applies a partial update - an Array of [code][name:String, type:int, value][/code] entries (see [method BehaviorGraphDebugBridge._send_blackboard_delta]) - without rebuilding unaffected rows.
func apply_blackboard_delta(deltas: Array) -> void:
	var root := blackboard_tree.get_root()
	if root == null:
		root = blackboard_tree.create_item()
	for entry in deltas:
		var var_name : String = entry[0]
		if _blackboard_rows.has(var_name):
			_update_blackboard_row(_blackboard_rows[var_name], entry[1], entry[2])
		else:
			_add_blackboard_row(root, var_name, entry[1], entry[2])

func _add_blackboard_row(root: TreeItem, var_name: String, type: int, value) -> void:
	var item := blackboard_tree.create_item(root)
	_blackboard_rows[var_name] = item
	item.set_text(0, var_name)
	_update_blackboard_row(item, type, value)

func _update_blackboard_row(item: TreeItem, type: int, value) -> void:
	item.set_icon(0, EditorInterface.get_editor_theme().get_icon(type_string(type), "EditorIcons"))
	item.set_tooltip_text(0, type_string(type))
	item.set_text(1, str(value))
