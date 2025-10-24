extends Node
class_name GameLogger

var game_dir_path

var log_file : FileAccess
var logs_folder : DirAccess

func _ready() -> void:
	game_dir_path = GlobalSaver.game_dir_path
	logs_folder = DirAccess.open(game_dir_path)
	if not logs_folder.dir_exists("logs"):
		logs_folder.make_dir_recursive("logs")
	logs_folder = DirAccess.open(game_dir_path + "/logs")
	log_file = FileAccess.open(game_dir_path + "/logs/" + str(Time.get_unix_time_from_system()) + ".log", FileAccess.WRITE)
	var files = logs_folder.get_files()
	if files.size() > 10:
		var oldest_log = files[0]
		for file in files:
			if file.trim_suffix(".log").to_int() <\
			oldest_log.trim_suffix(".log").to_int():
				oldest_log = file
		logs_folder.remove(game_dir_path + "/logs/" + oldest_log)
	GlobalLogger.write_to_logs(self, "Logger started. Hello!")

func write_to_logs(sender : Node, log_string : String) -> void:
	log_file.store_line(str(sender.get_path()) + " - " + log_string + ": " + Time.get_time_string_from_system() + ":" + str(int((Time.get_unix_time_from_system() - int(Time.get_unix_time_from_system()))*1000)))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		log_file.close()
