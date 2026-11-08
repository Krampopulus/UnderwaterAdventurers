extends Node
class_name GameConfigManager

var config_data: Dictionary = {}
const CONFIG_PATH = "res://data/game_config.json"

func _ready() -> void:
	load_config()

func load_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			config_data = json.get_data()
			print("⚙️ [КОНФИГ] Параметры успешно загружены из JSON.")
		else:
			push_error("❌ [КОНФИГ] Ошибка парсинга JSON: " + json.get_error_message())
	else:
		push_warning("⚠️ [КОНФИГ] Файл конфигурации не найден, используются значения по умолчанию.")

func get_setting(key: String, default_value: Variant) -> Variant:
	if config_data.has(key):
		return config_data[key]
	return default_value
