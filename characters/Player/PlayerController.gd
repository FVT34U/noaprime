extends Node
class_name PlayerController

@export_category("Components")
@export var player_movement_component: PlayerMovementComponent
@export var health_component: HealthComponent
@export var stamina_component: StaminaComponent
@export var weapon_component: WeaponComponent
@export var state_machine: CharacterStateMachine
@export var indicator_component: IndicatorComponent

@export_category("Stats")
@export var respawn_time = 5.0

@onready var camera = $PlayerMovementComponent/Head/SmoothCamera/Camera3D


var hud: HUDComponent
var world: GameMode

var is_menu_opened = false

signal death
signal respawn


@rpc("any_peer", "call_local")
func death_handler(init_id: int):
	# Death message to chat from server
	if multiplayer.is_server():
		world.rpc(
			'chat_message',
			1,
			"{pid} was killed by {initiator}".format(
				{
					"pid": ConnectionProperties.id_usernames[name.to_int()],
					"initiator": ConnectionProperties.id_usernames[init_id],
				}
			),
		)
		
		Logger.log("Message sended from server", 1)
	
	if is_multiplayer_authority():
		# Set cursor visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# death signal to all connected components
	death.emit()
	
	# Respawn timer
	await get_tree().create_timer(respawn_time).timeout
	_respawn()


func _respawn():
	if is_multiplayer_authority():
		# Hide cursor
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# respan signal to all connected components
	respawn.emit()
	
	# Set respawn position
	player_movement_component.global_position = world.get_spawnpoint()


func _enter_tree():
	# Set MP authority by id from node name
	set_multiplayer_authority(str(name).to_int())


func _unhandled_key_input(event):
	# If not local pawn - exit
	if not is_multiplayer_authority(): return
	
	# Game exit on Esc
	if Input.is_action_just_pressed("close"):
			get_tree().quit()
	
	# Open/close menu on Tab
	if Input.is_action_just_pressed("open_menu"):
		if not is_menu_opened:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			player_movement_component.disable_camera_control()
			player_movement_component.disable_movement()
			weapon_component.disable_shooting()
			is_menu_opened = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			player_movement_component.enable_camera_control()
			player_movement_component.enable_movement()
			weapon_component.enable_shooting()
			is_menu_opened = false
	
	# Interact
	if Input.is_action_just_pressed("interact"):
		var space_state = player_movement_component.get_world_3d().direct_space_state
		var screen_center = get_viewport().size / 2
		var origin = camera.global_position # sadly shooting from camera :-(
		var end = origin + \
			camera.project_ray_normal(screen_center) * \
			1000
		
		# shooting to any object
		var obj_query = PhysicsRayQueryParameters3D.create(
			origin,
			end,
			1,
			[
				player_movement_component,
				player_movement_component.head_hitbox,
				player_movement_component.body_hitbox,
			],
		)
		obj_query.collide_with_areas = false
		obj_query.collide_with_bodies = true
		var obj_result = space_state.intersect_ray(obj_query)
		
		if not obj_result:
			print("no object")
			return
		
		var coll = obj_result.get("collider")
		if not coll.has_meta("Interactable"): return
		coll.interact(self)


func _physics_process(_delta):
	# If not local pawn - exit
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("ads"):
		print(state_machine.State.find_key(state_machine.current_state))
		print(world.players_list)


func _ready():
	# Get ref to World
	if not world:
		world = get_parent()
	
	# If not local pawn - exit
	if not is_multiplayer_authority(): return
	
	# Creating HUD
	if not hud:
		hud = preload("res://characters/Player/HUD.tscn").instantiate()
		add_child(hud)
	
	# Set username
	world.rpc("register_player", multiplayer.get_unique_id(), ConnectionProperties.username)
	
	# Mouse cursor to game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# respawn as spawn) 
	respawn.emit()
