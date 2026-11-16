# BeGraph Documentation Hub

Welcome to the comprehensive documentation suite for **BeGraph**, an agentic Behavior Tree and visual Behavior Graph engine engineered for **Godot 4**.

Whether you are designing AI behaviors for 2D platformers, full-scale 3D action titles, or complex strategy games, this documentation covers everything from basic node authoring to advanced runtime telemetry.

---

## Table of Contents

### 1. Authoring Nodes
- **[Writing Classic Custom BehaviorNodes](custom_nodes.md)**  
  Learn how to create standard action and condition nodes extending `BehaviorNode`: script metadata (`DISPLAY_NAME`, `DISPLAY_ICON`), slot configuration, inline instruction formatting (`{property}` tokens), the node lifecycle (`on_start`, `tick`, `on_end`, `abort`), safe property evaluation via `eval()`, and multi-branch condition nodes.
- **[Writing Special Custom Nodes](special_nodes.md)**  
  Learn how to create specialized visual nodes using `DISPLAY_SCENE`: deep dive into `AccessPointNode` and `CommentNode`, inheriting from `BehaviorGraphNodeBase`, binding custom Godot controls in `_on_node_set()`, and building interactive custom node UIs.

### 2. Architecture & Data Flow
- **[The Blackboard System & Inline Editors](blackboard.md)**  
  Exhaustive guide to decoupled AI data: the `BlackboardVariable` resource, managing variables in the Inspector, inline variable editors, drag-and-drop blackboard variable assignment, visual drop validation, the type compatibility matrix (`BG.is_type_compatible`), and reactive binding.
- **[BehaviorAgent & NodePath Resolution](behavior_agent.md)**  
  Runtime execution engine: process loops (`IDLE`, `PHYSICS`, `MANUAL`), tick optimization with `tick_interval`, entry point selection, exposing blackboard variables (`export_variable`), and mastering **NodePath resolution**: why `_resolve_node()` strictly expects absolute paths, how internal hierarchy paths are auto-converted, and how to inject external dependencies via `set_blackboard_property()`.

### 3. Editor Configuration & Project Integration
- **[Categories and Node Scanning via Project Settings](categories_and_scanning.md)**  
  How to scan external folders (using `Additional Nodes` as a practical example) via `BeGraph/general_settings/custom_nodes_paths`, automatic folder-to-submenu hierarchy mapping, defining custom categories in `custom_categories`, and configuring bespoke background/border colors.
- **[Canvas Editing & Workflow Features](editing_and_workflow.md)**  
  Master productivity tools: deep-cloned Copy, Cut, Paste, and Duplicate (`Ctrl+C`, `Ctrl+X`, `Ctrl+V`, `Ctrl+D`), mouse-centered offset placement, blackboard rebinding rules, standard Frames vs executable Sequence Frames (`is_sequence = true`), the built-in Decorator Tree (Inverter, Repeater, Cooldown, Time Limit, Delay, Condition), and titlebar Breakpoint (`B`) / Mute (`M`) toggles.

### 4. Graph Composition & Modularity
- **[Embedding Graphs](embed_graphs.md)**  
  Inlining external `.tres` graph resources directly into the active canvas: automated frame wrapping, blackboard unbinding to avoid data corruption, access point stripping, and atomic undo/redo rollback.
- **[The Run Subgraph Node](run_subgraph.md)**  
  Modular hierarchical AI: executing external graphs at runtime without inlining, entry point targeting, name-based shared blackboard variable synchronization, runtime caching, recursion guards (`MAX_DEPTH = 16`), and cascading branch abortion.

### 5. Hands-on Showcases & Demos
- **[Gym 2D Showcase & Station Walkthrough](gym_2d.md)**  
  Detailed analysis of the 5 interactive stations in `res://addons/BeGraph/DEMO/gym_2d/gym_2d.tscn`: Station 1 Patrol (Once, Loop, Ping-Pong), Station 2 Sentry (Distance, LOS, Projectiles), Station 3 Tag Arena (NavigationAgent2D state switching), Station 4 Field of View (stealth detection cone), and Station 5 Ambient Behaviors (random sequences, tweens).
- **[Gym 3D Showcase & Station Walkthrough](gym_3d.md)**  
  Detailed analysis of the 5 interactive stations in `res://addons/BeGraph/DEMO/gym_3d/gym_3d.tscn`: Station 1 Elevation Patrol, Station 2 3D Sentry (spatial audio, spotlight tracking, projectile spawning), Station 3 Physics Impulse (Jolt Physics RigidBody strikes), Station 4 Drone Orbit (aerial hover navigation), and Station 5 Acrobat Jump (parallel composite flips and tweens).

### 6. Advanced Tools & Telemetry
- **[Live Debugging](live_debugging.md)**  
  The complete BeGraph telemetry stack: the Editor Debugger Panel (`BehaviorGraphDebuggerPlugin`), the `BeGraphDebugBridge` autoload, the In-Game Runtime Overlay (`F3`).
- **[Advanced Features ](advanced_features.md)** 
  Sequence Frame deterministic ordering with memory, Breakpoints, and the Node Info Panel.
---

## Media & Screenshot Placeholders
All documents in this documentation suite include structured image placeholders referencing images intended for the `docs/media/` directory. Each placeholder explicitly describes what scene, panel, or graph layout to capture. When creating your screenshots, save them in `.png` format matching the filenames referenced in each document.
