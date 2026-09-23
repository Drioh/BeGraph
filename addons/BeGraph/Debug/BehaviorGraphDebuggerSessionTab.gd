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
