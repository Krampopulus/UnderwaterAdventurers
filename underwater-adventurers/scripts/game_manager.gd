extends Node

# Вот эта строка создает поле в инспекторе Godot:
@export var danger_zone_node: Area3D

static var total_lost_value: float = 0.0

func _ready() -> void:
	if danger_zone_node:
		# Подключаем сигнал пересечения зоны
		danger_zone_node.body_entered.connect(_on_danger_zone_entered)
	else:
		print("⚠️ [GameManager] Внимание: не назначена Danger Zone Node в инспекторе!")

func _unhandled_input(event: InputEvent) -> void:
	# Debug-клавиша K (работает только в debug-сборке из редактора)
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_K:
		trigger_player_death("DEBUG: Принудительный сброс по клавише K")

func _on_danger_zone_entered(body: Node3D) -> void:
	# Проверяем, что в зону вошел именно игрок
	if body is CharacterBody3D:
		trigger_player_death("Вход в тестовую опасную зону")

func trigger_player_death(reason: String) -> void:
	print("☠️ [СМЕРТЬ] Экспедиция провалена! Причина: ", reason)
	total_lost_value = 350.0 # Фиксация потерянного лута
	
	# Перезапуск текущей сцены
	get_tree().reload_current_scene()
