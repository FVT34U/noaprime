extends MeshInstance3D

var exists_time = 5.0

func _ready():
	await get_tree().create_timer(exists_time).timeout
	queue_free()
