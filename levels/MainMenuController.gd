extends Control

@onready var username = $MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/UserNameInput
@onready var ip = $MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/IPInput

@onready var scene = load("res://levels/test_level.tscn") as PackedScene


func _ready() -> void:
	if DisplayServer.get_name() == 'headless':
		get_tree().call_deferred("change_scene_to_packed", scene)
	

func _on_play_btn_pressed() -> void:
	var ip_port = ip.get_text().split(":")
	
	print(ip_port)
	ConnectionProperties.ip = str(ip_port[0])
	ConnectionProperties.port = int(ip_port[1])
	
	get_tree().call_deferred("change_scene_to_packed", scene)
