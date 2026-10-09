@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Print message"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Prints {value} to the console with print() and always succeeds.\n\n {value} accepts any type; useful for debugging graph execution."

enum enum_di_prova{Primo_Valore, Secondo_Valore, Terzo_Valore}

@export_custom(BG.HINT_NONE,BG.PROPERTY,PROPERTY_USAGE_NIL_IS_VARIANT) var value =null
@export_custom(BG.HINT_ENUM,BG.ENUMERATOR + "enum_di_prova") var prova_enumeratore : enum_di_prova = 0
@export_custom(BG.HINT_ENUM,BG.PROPERTY + "enum_di_prova,scherzo,battutona") var prova_enumeratore_due : enum_di_prova = 0
@export_custom(BG.HINT_ENUM,BG.PROPERTY + "enum_di_prova,scherzo,battutona") var prova_enumeratore_tre : int = 0
@export_custom(BG.HINT_NONE,BG.PROPERTY) var stringa : String = ""

func tick(delta:float)->Status:
	print(value)
	tick_next(delta)
	return Status.SUCCESS 

func set_instruction() -> String:
	return "Prints {value} and {prova_enumeratore} and {stringa}"

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false
