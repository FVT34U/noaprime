extends Node3D


const PORT = 8080

@onready var player_scene = load('res://characters/Player/Player.tscn')
@onready var players_list_node = $PlayersList

@export var spawnpoints: Array[Node3D] = []
var _unavailable_spawnpoints: Array[Node3D] = []


func get_local_player() -> Node:
	for child in players_list_node.get_children():
		if child is Node and child.name == str(multiplayer.get_unique_id()):
			return child
	return null


@rpc("any_peer", "call_local")
func chat_message(sender_id: int, msg: String):
	var player = get_local_player()
	if player:
		if player.hud:
			player.hud.add_chat_message(sender_id, msg)


func add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	
	players_list_node.add_child(player)
	
	var sp = _get_random_unique_spawnpoint()
	player.player_movement_component.global_position = sp.global_position
	_unavailable_spawnpoints.append(sp)
	
	rpc(
		'chat_message',
		multiplayer.get_unique_id(),
		'Player {id} connected!'.format({"id": id}),
	)


func remove_player(id: int):
	players_list_node.get_node(str(id)).queue_free()
	rpc(
		'chat_message',
		 multiplayer.get_unique_id(),
		 'Player {id} disconnected!'.format({"id": id}),
	)


func get_spawnpoint() -> Vector3:
	var sp = _get_random_unique_spawnpoint()
	_unavailable_spawnpoints.append(sp)
	return sp.global_position

func _get_random_unique_spawnpoint():
	var available_points = spawnpoints.duplicate()

	# Удаляем уже выбранные значения из доступных значений
	for value in _unavailable_spawnpoints:
		available_points.erase(value)
	
	if available_points.size() == 1:
		_clear_unavailable_spawnpoints()
	
	if available_points.size() > 0:
		# Выбираем случайное значение из оставшихся
		var random_index = randi() % available_points.size()
		return available_points[random_index]
	else:
		return Node3D.new()

func _clear_unavailable_spawnpoints():
	await get_tree().create_timer(3).timeout
	_unavailable_spawnpoints.clear()

func _ready():
	var peer = ENetMultiplayerPeer.new()
	if DisplayServer.get_name() == 'headless':
		peer.create_server(PORT)
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
	else:
		peer.create_client('localhost', PORT)
		multiplayer.multiplayer_peer = peer
	
	_clear_unavailable_spawnpoints()
