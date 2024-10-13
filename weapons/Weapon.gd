extends Node3D
class_name Weapon

enum WEAPON_TYPE {
	PISTOL,
	SNIPER_RIFLE,
	MARKSMAN_RIFLE,
	ASSAULT_RIFLE,
	BATTLE_RIFLE,
	SMG,
	MACHINE_GUN,
	SHOTGUN,
}


@export var w_name: String
@export var type: WEAPON_TYPE
@onready var stats: WeaponStats = WeaponStats.new(w_name)

@onready var muzzle = $Muzzle
