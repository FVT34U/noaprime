extends Node
class_name Logger

static var current_log_name: String = ""

static func log(message, sender_id: int = 1):
	if DisplayServer.get_name() == 'headless':
		var dir = DirAccess.open("user://server-logs")
		
		if dir == null:
			dir = DirAccess.open("user://")
			dir.make_dir_recursive("user://server-logs")
		
		if current_log_name == "":
			var file_name = "server-log-{time}.txt".format({"time": DateTime.get_current_time()})
			var file_path = "user://server-logs/{file}".format({"file": file_name})
			current_log_name = file_path
			
			var temp_file = FileAccess.open(current_log_name, FileAccess.WRITE)
			temp_file.close()
		
		var file = FileAccess.open(current_log_name, FileAccess.READ_WRITE)
		file.seek_end()
		
		if file:
			file.store_string("[LOG][{timestamp}][{sender_id}][{name}]: {msg}\n".format({
				"timestamp": DateTime.get_current_time(),
				"sender_id": sender_id,
				"name": ConnectionProperties.id_usernames[sender_id],
				"msg": message,
			}))
			
			file.close()
		
		print("[LOG][{timestamp}][{sender_id} as {name}]: {msg}".format({
			"timestamp": DateTime.get_current_time(),
			"sender_id": sender_id,
			"name": ConnectionProperties.id_usernames[sender_id],
			"msg": message,
		}))
