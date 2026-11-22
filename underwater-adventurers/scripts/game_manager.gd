extends Node

# Сигналы для обновления интерфейса (UI)
signal credits_changed(new_amount: int)
signal expedition_failed(lost_value: int)

# Глобальные переменные
var credits: int = 0
var current_expedition_value: int = 0 # Стоимость лута, который игрок несёт прямо сейчас

func _ready() -> void:
	print("✅ [GameManager] Загружен и готов к работе.")
	# В будущем здесь будет загрузка credits из файла сохранения

# --- ЭКОНОМИКА ---
func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit(credits)
	print("💰 Получено: ", amount, ". Всего на счету: ", credits)

func add_to_expedition_value(amount: int) -> void:
	current_expedition_value += amount

func clear_expedition_value() -> void:
	current_expedition_value = 0

# --- СМЕРТЬ И ПЕРЕЗАПУСК ---
func trigger_player_death(reason: String) -> void:
	print("☠️ [СМЕРТЬ] Экспедиция провалена! Причина: ", reason)
	print("💸 Потеряно лута на сумму: ", current_expedition_value)
	
	# Сообщаем UI, чтобы он показал экран потерь (если нужно)
	expedition_failed.emit(current_expedition_value)
	
	# Сбрасываем значение текущей экспедиции перед перезапуском
	current_expedition_value = 0
	
	# Перезапуск текущей сцены
	get_tree().reload_current_scene()

# --- DEBUG ---
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_K:
		trigger_player_death("DEBUG: Принудительный сброс по клавише K")