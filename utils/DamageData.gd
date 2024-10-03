extends Node
class_name DamageData

enum DAMAGE_TYPE {BASE, EXPLOSION, ELECTRIC}

var value: float
var multiplier: float
var type: DAMAGE_TYPE
var initiator_id: int


static func get_type():
	return DAMAGE_TYPE

func _init(value: float, multiplier: float, type: DAMAGE_TYPE, initiator_id: int):
	self.value = value
	self.multiplier = multiplier
	self.type = type
	self.initiator_id = initiator_id
	
func to_dict() -> Dictionary:
	return {
		"value": self.value,
		"multiplier": self.multiplier,
		"type": self.type,
		"initiator_id": self.initiator_id,
	}
	
static func from_dict(dict: Dictionary) -> DamageData:
	return DamageData.new(
		dict["value"],
		dict["multiplier"],
		dict["type"],
		dict["initiator_id"],
	)
