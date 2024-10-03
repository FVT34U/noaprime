extends Node
class_name HealthComponent

@export var max_health: float = 100.0
@export var controller: PlayerController

@onready var health = max_health

var _can_take_damage = true

signal health_value_changed(new_hp: float)

func _death(init_id: int):
	if not is_multiplayer_authority(): return
	
	_can_take_damage = false
	
	if controller.has_method("death_handler"):
		controller.rpc(
			'death_handler',
			init_id,
		)


func take_damage(dmg: DamageData):
	if not _can_take_damage: return
	
	health -= dmg.value * dmg.multiplier
	health_value_changed.emit(health)

	if is_zero_approx(health):
		_death(dmg.initiator_id)


func _ready():
	controller.respawn.connect(_on_respawn)
	
	await get_tree().create_timer(1).timeout
	health_value_changed.emit(health)


func _on_respawn():
	_can_take_damage = true
	health = max_health
	health_value_changed.emit(health)
