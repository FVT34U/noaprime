extends Node
class_name WeaponComponent

@export_category("Components")
@export var active_weapon_slot: Node3D
@export var controller: PlayerController

@export_category("Stats")
@export var shot_impact_exist_time = 5.0

# shooting impact
@onready var test_sphere = preload("res://utils/TestSphere.tscn")


enum SHOOTING_MODE {AUTO, SEMI_AUTO}
var cur_shooting_mode = SHOOTING_MODE.SEMI_AUTO

var can_shoot = false

func enable_shooting():
	can_shoot = true
	
func disable_shooting():
	can_shoot = false


func have_gun() -> bool:
	if active_weapon_slot.get_child_count() != 0:
		return true
	return false
	
func get_gun():
	return active_weapon_slot.get_child(0)

func shoot():
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
		[controller.player_movement_component],
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
		# debug, make it for impact things
		var t = test_sphere.instantiate()
		t.position = obj_result.get("position")
		t.exists_time = shot_impact_exist_time
		controller.world.add_child(t)
	
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
				controller.multiplayer.get_unique_id(),
			)
			collider.rpc("take_damage", dmg.to_dict())


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		if not have_gun():
			return
		shoot()


func _ready():
	if not is_multiplayer_authority(): return
	
	controller.death.connect(_on_death)
	controller.respawn.connect(_on_respawn)


func _on_death():
	disable_shooting()

func _on_respawn():
	enable_shooting()
