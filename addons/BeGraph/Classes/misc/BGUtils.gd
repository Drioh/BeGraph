class_name BG extends Node

#@export_custom(BG.HINT_ENUM,BG.ENUMERATOR + "enumerator_name") var var_name : enumerator_name = 0
#@export_custom(BG.HINT_ENUM,BG.PROPERTY + "val_1,val_2,...,val_n") var var_name : enumerator_name = 0
#@export_custom(BG.HINT_ENUM,BG.PROPERTY + "val_1,val_2,...,val_n") var var_name : int = 0
const HINT_NONE : PropertyHint = PROPERTY_HINT_NONE
const HINT_ENUM : PropertyHint = PROPERTY_HINT_ENUM
const HINT_MULTILINE_TEXT : PropertyHint = PROPERTY_HINT_MULTILINE_TEXT

const PROPERTY : String = "BeGraph:property:"
const ENUMERATOR : String = "BeGraph:enumerator:"
const CONDITION : String = "BeGraph:condition:"

## Messages exchanged via EngineDebugger between game (Bridge) and editor (Plugin).
## Formerly its own class (BeGraphProtocol, Debug/BehaviorGraphProtocol.gd), folded in here
## so every addon-wide constant lives in a single place.
class Protocol:
	const PREFIX : String = "begraph"
	const GRAPH : String = "begraph:graph"
	const STATUS : String = "begraph:status"
	const PROPERTIES : String = "begraph:properties"
	const BLACKBOARD : String = "begraph:blackboard"
	const REMOVED : String = "begraph:removed"

	static func safe_value(value: Variant) -> Variant:
		return str(value) if value is Object else value
