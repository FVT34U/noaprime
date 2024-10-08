extends Node
class_name Logger


static func log(message, sender_id: int = 1):
	print("[LOG][{timestamp}][{sender_id} as {name}]: {msg}".format({
		"timestamp": DateTime.get_current_time(),
		"sender_id": sender_id,
		"name": ConnectionProperties.id_usernames[sender_id],
		"msg": message,
	}))
