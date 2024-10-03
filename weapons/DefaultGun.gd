extends Node3D
class_name DefaultGun


@export_category("Damage")
@export var damage: float
@export var headshot_multiplier: float

@export_category("Range")
@export var max_range: float
@export var range_multiplier: float

@export_category("Recoil Control")
@export var v_recoil: float
@export var h_recoil: float

@export_category("Fire Rate")
@export var fire_rate: float

@export_category("Handling")
@export var reload_time: float
@export var ads_speed: float
@export var stf_speed: float
@export var swap_speed: float

@export_category("Accuracy")
@export var hipfire_spread: float
@export var move_spread: float
@export var air_spread: float

@export_category("Mobility")
@export var movement_speed: float
@export var ads_movement_speed: float
@export var crouch_movement_speed: float
@export var sprint_speed: float


@onready var muzzle = $Muzzle


func shoot():
	pass

func reload():
	pass

func aim():
	pass
