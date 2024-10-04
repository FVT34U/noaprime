extends Control


@onready var chat = \
$Interface/VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer/Chat
@onready var chat_input = \
$Interface/VBoxContainer/HBoxContainer/VBoxContainer/ChatInput
@onready var chat_scroll = \
$Interface/VBoxContainer/HBoxContainer/VBoxContainer/ScrollContainer
@onready var health_value_label = \
$Interface/VBoxContainer/Control/HBoxContainer/Control/HBoxContainer/HealthValue
@onready var stamina_value_label = \
$Interface/VBoxContainer/Control/HBoxContainer/Control/HBoxContainer2/StaminaValue

@onready var interface = $Interface
@onready var crosshair = $Crosshair
@onready var death_screen = $DeathScreen

@onready var controller = get_parent()

var _is_chat_open = false

var start = Vector2()
var end = Vector2()
var color = Color(1, 0, 0)
var width = 1


func add_chat_message(sender_id: int, msg: String):
	var msg_label = Label.new()
	msg_label.text = '[{id}]: {msg}'.format({"id": sender_id, "msg": msg})
	
	chat.add_child(msg_label)
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value


func _draw():
	draw_line(start, end, color, width)
	pass


func _unhandled_key_input(event):
	if event.is_action_pressed("enter"):
		if not _is_chat_open:
			chat_input.grab_focus()
			controller.player_movement_component.disable_movement()
			controller.player_movement_component.disable_camera_control()
			controller.weapon_component.disable_shooting()


func _ready():
	if not controller: return
	
	controller\
	.health_component\
	.health_value_changed\
	.connect(_on_health_value_changed)
	
	controller\
	.stamina_component\
	.stamina_value_changed\
	.connect(_on_stamina_value_changed)
	
	#queue_redraw()
	
	controller.death.connect(_on_death)
	controller.respawn.connect(_on_respawn)


func _on_chat_input_text_submitted(new_text):
	if new_text != "":
		chat_input.clear()
		controller.world.rpc(
			'chat_message',
			controller.multiplayer.get_unique_id(),
			new_text,
		)
		chat_input.release_focus()
		controller.player_movement_component.enable_movement()
		controller.player_movement_component.enable_camera_control()
		controller.weapon_component.enable_shooting()
		
		chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value


func _on_chat_input_text_change_rejected(rejected_substring):
	chat_input.clear()
	chat_input.release_focus()
	controller.player_movement_component.enable_movement()
	controller.player_movement_component.enable_camera_control()
	controller.weapon_component.enable_shooting()


func _on_chat_input_focus_exited():
	chat_input.clear()
	chat_input.release_focus()
	controller.player_movement_component.enable_movement()
	controller.player_movement_component.enable_camera_control()
	controller.weapon_component.enable_shooting()


func _on_health_value_changed(new_hp: float):
	health_value_label.set_text(str(new_hp))
	
func _on_stamina_value_changed(new_stamina: float):
	stamina_value_label.set_text(str(new_stamina))


func _on_death():
	death_screen.visible = true
	crosshair.visible = false
	interface.visible = false
	
func _on_respawn():
	death_screen.visible = false
	crosshair.visible = true
	interface.visible = true
