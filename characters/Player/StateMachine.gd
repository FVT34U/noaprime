extends Node
class_name CharacterStateMachine

@export_category("Components")
@export var controller: PlayerController
@export var movement_component: PlayerMovementComponent

enum State {
	IDLE,
	WALK,
	FLY,
	SPRINT,
	CROUCH,
}

var current_state = State.IDLE


# maybe needs to be private
func update_state():
	var state = State.IDLE
	
	if movement_component.velocity.length() > 1.0:
		if movement_component.is_sprinting:
			state = State.SPRINT
		elif movement_component.is_crouching:
			state = State.CROUCH
		else:
			state = State.WALK
	else:
		if movement_component.is_crouching:
			state = State.CROUCH
		else:
			state = State.IDLE
	
	if not movement_component.is_on_floor(): state = State.FLY
	
	current_state = state


func _ready():
	controller.death.connect(_on_death)

func _physics_process(delta):
	update_state()


func _on_death():
	current_state = State.IDLE
