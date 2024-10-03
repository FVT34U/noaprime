extends Node
class_name StaminaComponent

@export_category("Stats")
@export var max_stamina: float = 100
@export var stamina_regen_value: float = 15
@export var stamina_decrease_value: float = 25

@export_category("Components")
@export var controller: PlayerController
@export var movement_component: PlayerMovementComponent
@export var state_machine: CharacterStateMachine

@onready var stamina = max_stamina

signal stamina_value_changed(new_stamina: float)
signal stamina_is_over


func _decrease_stamina(delta: float):
	stamina -= stamina_decrease_value * delta
	if stamina <= 0.0:
		stamina = 0.0
		stamina_is_over.emit()
	
	stamina_value_changed.emit(stamina)

func _regenerate_stamina(delta: float):
	stamina += stamina_regen_value * delta
	if stamina >= max_stamina:
		stamina = max_stamina
	
	stamina_value_changed.emit(stamina)


func _unhandled_input(event):
	if not is_multiplayer_authority(): return

func _ready():
	await get_tree().create_timer(1).timeout
	stamina_value_changed.emit(stamina)
	
func _physics_process(delta):
	if state_machine.current_state == state_machine.State.SPRINT:
		_decrease_stamina(delta)
	else:
		if not state_machine.current_state == state_machine.State.FLY:
			_regenerate_stamina(delta)
