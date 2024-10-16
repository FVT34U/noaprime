extends Node3D
class_name VehicleController

@export_category("Components")
@export var movement_component: VehicleMovementComponent

@onready var driver_seat = $VehicleMovementComponent/DriverSeat

var is_possessed = false
var driver: PlayerController


func interact(controller: PlayerController):
	if is_possessed == true:
		is_possessed = false
		movement_component.remove_child(driver)
		driver.player_movement_component.enable_movement()
		driver = null
		return
	
	is_possessed = true
	driver = controller
	movement_component.add_child(driver)
	driver.player_movement_component.global_position = driver_seat.global_position
	driver.player_movement_component.disable_movement()
