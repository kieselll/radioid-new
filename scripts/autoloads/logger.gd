extends Node
class_name GameLogger

var game_dir_path

var _log_file: FileAccess
var _log_file_path: String
var _logs_folder: DirAccess


func _ready() -> void:
	game_dir_path = GlobalSaver.game_dir_path
	_logs_folder = DirAccess.open(game_dir_path)
	if not _logs_folder.dir_exists("logs"):
		_logs_folder.make_dir_recursive("logs")
	_logs_folder = DirAccess.open(game_dir_path + "/logs")
	_log_file_path = game_dir_path + "/logs/" + str(Time.get_unix_time_from_system()) + ".log"
	_log_file = FileAccess.open(_log_file_path, FileAccess.WRITE)
	var files = _logs_folder.get_files()
	if files.size() > 10:
		var oldest_log = files[0]
		for file in files:
			if file.trim_suffix(".log").to_int() < oldest_log.trim_suffix(".log").to_int():
				oldest_log = file
		_logs_folder.remove(game_dir_path + "/logs/" + oldest_log)
	GlobalLogger.write_to_logs(self, "Logger started. Hello!")


func open_log_file():
	var log_path = _log_file_path
	if not FileAccess.file_exists(log_path):
		push_warning("Tried to open log file, but it doesn't exist!")
		return
	OS.shell_open(ProjectSettings.globalize_path(log_path))


func write_to_logs(sender: Node, log_string: String) -> void:
	_log_file.store_line(
		(
			str(sender.get_path())
			+ " - "
			+ log_string
			+ ": "
			+ Time.get_time_string_from_system()
			+ ":"
			+ str(
				int(
					(
						(Time.get_unix_time_from_system() - int(Time.get_unix_time_from_system()))
						* 1000
					)
				)
			)
		)
	)
	_log_file.flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_log_file.close()
