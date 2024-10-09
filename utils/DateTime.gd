extends Node
class_name DateTime

static func get_current_time() -> String:
	var current_time = Time.get_datetime_dict_from_system()
	return "%02d-%02d-%02d" % [current_time["hour"], current_time["minute"], current_time["second"]]
