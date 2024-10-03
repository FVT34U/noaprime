extends CharacterBody3D
class_name PlayerMovementComponent

@export_category("Components")
@export var player_controller: PlayerController
@export var stamina_component: StaminaComponent

@export_category("Movement")
@export var max_speed = 5.0
@export var sprint_multiplier = 1.5
@export var crouch_multiplier = 0.5
@export var jump_velocity = 4.5
@export var h_acceleration = 6
@export var air_acceleration = 1.0
@export var normal_acceleration = 6
@export var max_step_height = 0.5

@export_category("Mouse")
@export var mouse_sensitivity = 0.3
@export var mouse_sens_multiplier = 1

var _movement_lock = true
var _mouse_lock = true

var camera_tilt = 0.0
var camera_limit = 89.0
var _saved_camera_global_pos = null

var full_contact = false
var h_velocity = Vector3()
var gravity_vector = Vector3()
var _snapped_to_stairs = false
var _last_frame_was_on_floor = -INF

var is_crouching = false
var is_sprinting = false

var speed_multiplier = 1.0

@onready var camera = $Head/SmoothCamera/Camera3D
@onready var head = $Head
@onready var ground_check = $GroundCheck
@onready var mesh_coll = $MeshCollision
@onready var head_coll = $HeadHitBox/HeadCollision
@onready var body_coll = $BodyHitBox/BodyCollision


func enable_movement():
	_movement_lock = false
	
func disable_movement():
	_movement_lock = true
	
func enable_camera_control():
	_mouse_lock = false
	
func disable_camera_control():
	_mouse_lock = true


func _is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle
	
func _run_body_test_motion(from: Transform3D, motion: Vector3, result=null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)

func _snap_down_to_stairs_check() -> void:
	var did_snap = false
	var floor_below = %StairsBelowRayCast3D.is_colliding()\
		and not _is_surface_too_steep(%StairsBelowRayCast3D.get_collision_normal())
	var was_on_floor_last_frame =\
		Engine.get_physics_frames() - _last_frame_was_on_floor == 1
	
	if not is_on_floor()\
		and velocity.y <= 0\
		and (was_on_floor_last_frame or _snapped_to_stairs)\
		and floor_below:
		
		var body_test_result = PhysicsTestMotionResult3D.new()
		
		if _run_body_test_motion(
			self.global_transform,
			Vector3(0, -max_step_height, 0),
			body_test_result
		):
			_save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs = did_snap

func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs: return false
	
	var expected_move_motion = self.velocity * Vector3(1, 0, 1) * delta
	var step_pos_with_clearance = self.global_transform.translated(
		expected_move_motion + Vector3(0, max_step_height * 2, 0)
	)
	var down_check_result = PhysicsTestMotionResult3D.new()
	
	# Add this to "if" state if not working
	# and (down_check_result.get_collider().is_class("StaticBody3D")
	# or down_check_result.get_collider().is_class("CSGShape3D"))
	if (_run_body_test_motion(
		step_pos_with_clearance,
		Vector3(0, -max_step_height * 2, 0),
		down_check_result,
	)):
		var step_height = ((step_pos_with_clearance.origin\
			+ down_check_result.get_travel()) - self.global_position).y
		
		if step_height > max_step_height\
			or step_height <= 0.01\
			or (down_check_result.get_travel() - self.global_position).y > max_step_height:
			return false
		
		%StairsAheadRayCast3D.global_position = down_check_result.get_collision_point()\
			+ Vector3(0, max_step_height, 0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		
		if %StairsAheadRayCast3D.is_colliding()\
			and not _is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			_save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin\
				+ down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs = true
			return true
	return false

func _save_camera_pos_for_smoothing():
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = %SmoothCamera.global_position

func _slide_camera_smooth_back_to_origin(delta):
	if _saved_camera_global_pos == null: return
	
	%SmoothCamera.global_position.y = _saved_camera_global_pos.y
	%SmoothCamera.position.y = clampf(%SmoothCamera.position.y, -0.7, 0.7)
	var move_amount = max(self.velocity.length() * delta, max_speed / 2 * delta)
	%SmoothCamera.position.y = move_toward(%SmoothCamera.position.y, 0.0, move_amount)
	_saved_camera_global_pos = %SmoothCamera.global_position
	if %SmoothCamera.position.y == 0:
		_saved_camera_global_pos = null
		%SmoothCamera.position = Vector3() # camera x and z slide fix


func _movement(delta):
	full_contact = ground_check.is_colliding()
	
	if not is_on_floor() and not _snapped_to_stairs:
		velocity += get_gravity() * delta
		gravity_vector += get_gravity() * delta
		h_acceleration = air_acceleration
	elif (is_on_floor() and full_contact) or _snapped_to_stairs:
		gravity_vector = -get_floor_normal() * get_gravity()
		h_acceleration = normal_acceleration
	else:
		gravity_vector = -get_floor_normal()
		h_acceleration = normal_acceleration
	
	if not _movement_lock:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

	var input_dir = Vector2(0, 0)
	if not _movement_lock:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	h_velocity = lerp(h_velocity, direction * max_speed * speed_multiplier, h_acceleration * delta)

	velocity.x = h_velocity.x + gravity_vector.x
	velocity.z = h_velocity.z + gravity_vector.z
	
	# For stairs, cause we changing global_position manualy
	if not _snap_up_stairs_check(delta):
		move_and_slide()
		_snap_down_to_stairs_check()
	
	_slide_camera_smooth_back_to_origin(delta)


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and not _mouse_lock:
		rotation.y -= deg_to_rad(event.relative.x * mouse_sensitivity * mouse_sens_multiplier)
		
		camera_tilt -= event.relative.y * mouse_sensitivity * mouse_sens_multiplier
		camera_tilt = clamp(camera_tilt, -camera_limit, camera_limit)
		
		head.rotation.x = deg_to_rad(camera_tilt)
	
	if Input.is_action_just_pressed("crouch"):
		if is_crouching:
			is_crouching = false
			speed_multiplier = 1.0
		else:
			is_crouching = true
			is_sprinting = false
			speed_multiplier = crouch_multiplier
	
	if Input.is_action_just_pressed("sprint"):
		if is_sprinting:
			is_sprinting = false
			speed_multiplier = 1.0
		else:
			is_sprinting = true
			is_crouching = false
			speed_multiplier = sprint_multiplier


func _ready():
	player_controller.death.connect(_on_death)
	player_controller.respawn.connect(_on_respawn)
	
	stamina_component.stamina_is_over.connect(_on_stamina_is_over)
	
	if not is_multiplayer_authority(): return
	
	camera.current = true


func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	_movement(delta)
	
	if is_on_floor(): _last_frame_was_on_floor = Engine.get_physics_frames()


func _on_death():
	mesh_coll.set_disabled(true)
	head_coll.set_disabled(true)
	body_coll.set_disabled(true)
	
	if not is_multiplayer_authority(): return
	
	disable_camera_control()
	disable_movement()

func _on_respawn():
	mesh_coll.set_disabled(false)
	head_coll.set_disabled(false)
	body_coll.set_disabled(false)
	
	if not is_multiplayer_authority(): return
	
	enable_camera_control()
	enable_movement()
	
func _on_stamina_is_over():
	is_sprinting = false
	speed_multiplier = 1.0
