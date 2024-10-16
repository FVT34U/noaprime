extends Node3D
class_name VehicleController

@export_category("Components")
@export var movement_component: VehicleMovementComponent

@onready var driver_seat = $VehicleMovementComponent/DriverSeat
@onready var world = get_parent()

var is_possessed = false
var driver: PlayerController


func interact(controller: PlayerController):
	if is_possessed == true:
		is_possessed = false
		remove_child(driver)
		world.add_child(driver)
		driver.player_movement_component.enable_movement()
		driver = null
		return
	
	is_possessed = true
	driver = controller
	world.remove_child(driver)
	add_child(driver)
	driver.player_movement_component.global_position = driver_seat.global_position
	driver.player_movement_component.disable_movement()
