extends Node
class_name WeaponStats


# Damage
var damage: float
var headshot_multiplier: float

# Ammo
var clip_size: int

# Range
var max_range: float
var range_multiplier: float

# Recoil Control
var v_recoil: float
var h_recoil: float

# Fire Rate
var fire_rate: float

# Handling
var reload_time: float
var ads_speed: float
var stf_speed: float
var swap_speed: float

# Accuracy
var hipfire_spread: float
var move_spread: float
var air_spread: float

# Mobility
var movement_speed: float
var ads_movement_speed: float
var crouch_movement_speed: float
var sprint_speed: float


func load_from_ini(name: String):
	var cfg = ConfigFile.new()
	cfg.load("res://weapons/weapon_stats.ini")
	
	damage = cfg.get_value(name, "damage")
	headshot_multiplier = cfg.get_value(name, "headshot_multiplier")
	clip_size = cfg.get_value(name, "clip_size")
	max_range = cfg.get_value(name, "max_range")
	range_multiplier = cfg.get_value(name, "range_multiplier")
	v_recoil = cfg.get_value(name, "v_recoil")
	h_recoil = cfg.get_value(name, "h_recoil")
	fire_rate = cfg.get_value(name, "fire_rate")
	reload_time = cfg.get_value(name, "reload_time")
	ads_speed = cfg.get_value(name, "ads_speed")
	stf_speed = cfg.get_value(name, "stf_speed")
	swap_speed = cfg.get_value(name, "swap_speed")
	hipfire_spread = cfg.get_value(name, "hipfire_spread")
	move_spread = cfg.get_value(name, "move_spread")
	air_spread = cfg.get_value(name, "air_spread")
	movement_speed = cfg.get_value(name, "movement_speed")
	ads_movement_speed = cfg.get_value(name, "ads_movement_speed")
	crouch_movement_speed = cfg.get_value(name, "crouch_movement_speed")
	sprint_speed = cfg.get_value(name, "sprint_speed")


func _init(name: String):
	load_from_ini(name)
