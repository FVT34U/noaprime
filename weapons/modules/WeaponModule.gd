extends Node
class_name WeaponModule

enum WEAPON_MODULE_TYPE {
	BARREL,
	UNDERBARREL,
	STOCK,
	CLIP,
	OPTICS,
}

@export_category("Type")
@export var weapon_module_type: WEAPON_MODULE_TYPE = WEAPON_MODULE_TYPE.BARREL
