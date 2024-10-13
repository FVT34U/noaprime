extends Node3D
class_name WeaponModule

enum WEAPON_MODULE_TYPE {
	BARREL,
	UNDERBARREL,
	STOCK,
	CLIP,
	OPTICS,
}

@export var wm_name: String
@export var type: WEAPON_MODULE_TYPE
@onready var stats = null # WeaponModuleStats
