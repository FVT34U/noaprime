extends Sprite3D


@export_category("Components")
@export var state_machine: CharacterStateMachine


func _ready():
	if is_multiplayer_authority():
		visible = false

func _physics_process(delta):
	if is_multiplayer_authority(): return
	
	if state_machine.current_state == state_machine.State.CROUCH:
		visible = false
	else:
		visible = true
