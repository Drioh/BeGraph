@tool
class_name BeGraphProtocol
extends RefCounted
## Messages exchanged via EngineDebugger between game (Bridge) and editor (Plugin).

const PREFIX :String= "begraph"
const GRAPH :String= "begraph:graph"
const STATUS :String= "begraph:status"
const PROPERTIES :String= "begraph:properties"
const BLACKBOARD :String= "begraph:blackboard"
const REMOVED :String= "begraph:removed"

static func safe_value(value: Variant) -> Variant:
	return str(value) if value is Object else value
