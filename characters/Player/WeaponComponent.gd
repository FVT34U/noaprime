extends Node
class_name WeaponComponent

@export_category("Components")
@export var active_weapon_slot: Node3D
@export var controller: PlayerController
@export var fire_rate_timer: Timer
@export var reload_timer: Timer

@export_category("Stats")
@export var shot_impact_exist_time = 5.0


enum SHOOTING_MODE {AUTO, SEMI_AUTO}
var cur_shooting_mode = SHOOTING_MODE.AUTO

var clip_size: int
var cur_rounds: int
var stored_ammo: int = 300

var can_shoot = false
var is_reloading = false

signal rounds_value_changed(rounds_new_val: int)
signal stored_ammo_value_changed(stored_ammo_new_value: int)


func enable_shooting():
	can_shoot = true
	
func disable_shooting():
	can_shoot = false


func have_gun() -> bool:
	if active_weapon_slot.get_child_count() != 0:
		return true
	return false
	
func get_gun() -> DefaultGun:
	return active_weapon_slot.get_child(0)

@rpc("authority", "call_remote")
func shoot(owner_id: int):
	if not multiplayer.is_server(): return
	
	var space_state = controller.player_movement_component.get_world_3d().direct_space_state
	var screen_center = get_viewport().size / 2
	var origin = controller.camera.global_position # sadly shooting from camera :-(
	var end = origin + \
		controller.camera.project_ray_normal(screen_center) * \
		get_gun().max_range
	
	# Debug ray from start to end point translated to screen coords
	#controller.hud.start = controller.camera.unproject_position(origin)
	#controller.hud.end = controller.camera.unproject_position(end)
	#controller.hud.queue_redraw()
	
	# shooting to any object and create an impact
	var obj_query = PhysicsRayQueryParameters3D.create(
		origin,
		end,
		1,
		[
			controller.player_movement_component,
			controller.player_movement_component.head_hitbox,
			controller.player_movement_component.body_hitbox,
		],
	)
	obj_query.collide_with_areas = false
	obj_query.collide_with_bodies = true
	var obj_result = space_state.intersect_ray(obj_query)
	
	# shooting only to hitboxes and do damage
	var hit_query = PhysicsRayQueryParameters3D.create(
		origin,
		end,
		4096,
		[
			controller.player_movement_component,
			controller.player_movement_component.head_hitbox,
			controller.player_movement_component.body_hitbox,
		],
	)
	hit_query.collide_with_areas = true
	hit_query.collide_with_bodies = false
	var hit_result = space_state.intersect_ray(hit_query)
	
	if not obj_result and not hit_result:
		return
	
	if obj_result:
		# Weapon impact
		controller.world.rpc("spawn_weapon_impact", obj_result.get("position"), obj_result.get("normal"))
	
	if hit_result:
		var collider = hit_result.get("collider")
		
		if collider is HitboxComponent:
			var multiplier = 1.0
			var type = collider.get_hitbox_type()
			match type:
				HitboxType.HITBOX_TYPE.ANY:
					multiplier = 1.0
				HitboxType.HITBOX_TYPE.BODY:
					multiplier = 1.0
				HitboxType.HITBOX_TYPE.HEAD:
					multiplier = get_gun().headshot_multiplier
				_: multiplier = 1.0
				
			var dmg = DamageData.new(
				get_gun().damage,
				multiplier,
				DamageData.get_type().BASE,
				owner_id,
			)
			collider.rpc("take_damage", dmg.to_dict())

func _shoot_handle():
	rpc("shoot", multiplayer.get_unique_id())
	can_shoot = false
	fire_rate_timer.start(get_gun().fire_rate)
	cur_rounds -= 1
	rounds_value_changed.emit(cur_rounds)
	if cur_rounds <= 0:
		can_shoot = false
		is_reloading = true
		reload_timer.start(get_gun().reload_time)


func reload():
	can_shoot = false
	is_reloading = true
	reload_timer.start(get_gun().reload_time)


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if not have_gun(): return
	
	if is_reloading: return
	
	# Reloading
	if Input.is_action_just_pressed("reload"):
		reload()
	
	# Change shooting mode
	if Input.is_action_just_pressed("change_shooting_mode"):
		if cur_shooting_mode == SHOOTING_MODE.SEMI_AUTO:
			cur_shooting_mode = SHOOTING_MODE.AUTO
		elif cur_shooting_mode == SHOOTING_MODE.AUTO:
			cur_shooting_mode = SHOOTING_MODE.SEMI_AUTO
	
	if not can_shoot: return
	
	if cur_shooting_mode == SHOOTING_MODE.SEMI_AUTO:
		if Input.is_action_just_pressed("shoot"):
			_shoot_handle()
	elif cur_shooting_mode == SHOOTING_MODE.AUTO:
		if Input.is_action_pressed("shoot"):
			_shoot_handle()


func _ready():
	if not is_multiplayer_authority(): return
	
	controller.death.connect(_on_death)
	controller.respawn.connect(_on_respawn)
	
	clip_size = get_gun().clip_size
	cur_rounds = clip_size
	
	stored_ammo -= clip_size # Need to be expanded for check stored_ammo value before subtraction
	cur_rounds = clip_size
	
	await get_tree().create_timer(1).timeout
	rounds_value_changed.emit(cur_rounds)
	stored_ammo_value_changed.emit(stored_ammo)


func _on_death():
	disable_shooting()

func _on_respawn():
	enable_shooting()


func _on_fire_rate_timer_timeout() -> void:
	can_shoot = true


func _on_reload_timer_timeout() -> void:
	can_shoot = true
	is_reloading = false
	
	stored_ammo -= clip_size # Need to be expanded for check stored_ammo value before subtraction
	cur_rounds = clip_size
	
	rounds_value_changed.emit(cur_rounds)
	stored_ammo_value_changed.emit(stored_ammo)
