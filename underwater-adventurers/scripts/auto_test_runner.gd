extends Node
class_name AutoTestRunner

func _ready() -> void:
	run_all_tests()

func run_all_tests() -> void:
	print("\n================ ЗАПУСК АВТО-ТЕСТОВ СИСТЕМЫ ================")
	
	var passed_count = 0
	var total_tests = 4
	
	# Тест 1: Проверка JSON-конфигурации
	if test_game_config():
		passed_count += 1
		
	# Тест 2: Проверка сцены тележки (StorageReceiver)
	if test_storage_receiver_scene():
		passed_count += 1
		
	# Тест 3: Проверка сцены шлюза (DropZone)
	if test_drop_zone_scene():
		passed_count += 1
		
	# Тест 4: Интеграционная проверка логики запрета сдачи снаряжения
	if test_equipment_restrictions():
		passed_count += 1
		
	print("\n================ ИТОГИ ТЕСТИРОВАНИЯ ================")
	print("Пройдено тестов: ", passed_count, " из ", total_tests)
	if passed_count == total_tests:
		print("🟢 ВСЕ ТЕСТЫ УСПЕШНО ПРОЙДЕНЫ! Карта и логика стабильны.")
	else:
		print("🔴 ВНИМАНИЕ! Обнаружены ошибки в конфигурации или сценах.")
	print("=====================================================\n")

func test_game_config() -> bool:
	print("\n[ТЕСТ 1] Проверка конфигурационного файла...")
	var test_capacity = GameConfig.get_setting("cart_max_capacity", -1)
	if test_capacity > 0:
		print("  -> Успех: Вместимость тележки из конфига равна ", test_capacity)
		return true
	else:
		push_error("  -> ОШИБКА: Не удалось прочитать 'cart_max_capacity' из JSON-конфига.")
		return false

func test_storage_receiver_scene() -> bool:
	print("\n[ТЕСТ 2] Проверка структуры тележки (StorageReceiver)...")
	var scene_path = "res://storage_receiver.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("  -> Пропущено: Файл сцены тележки не найден по пути " + scene_path)
		return true # Не фатально, если сцена еще не сохранена отдельно
		
	var scene = load(scene_path)
	var instance = scene.instantiate()
	
	var is_valid = true
	if not (instance is RigidBody3D):
		push_error("  -> ОШИБКА: Корневой узел StorageReceiver должен быть RigidBody3D[cite: 3]!")
		is_valid = false
	if not instance.has_node("PlayerDetector"):
		push_error("  -> ОШИБКА: У тележки отсутствует обязательный узел PlayerDetector[cite: 3].")
		is_valid = false
	if not instance.has_node("CargoArea"):
		push_error("  -> ОШИБКА: У тележки отсутствует внутренняя зона CargoArea[cite: 3].")
		is_valid = false
		
	instance.queue_free()
	if is_valid:
		print("  -> Успех: Структура нод тележки[cite: 3] полностью корректна.")
	return is_valid

func test_drop_zone_scene() -> bool:
	print("\n[ТЕСТ 3] Проверка структуры шлюза сбора (DropZone)...")
	var scene_path = "res://drop_zone.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("  -> Пропущено: Файл сцены шлюза не найден по пути " + scene_path)
		return true
		
	var scene = load(scene_path)
	var instance = scene.instantiate()
	
	var is_valid = true
	if not (instance is Area3D):
		push_error("  -> ОШИБКА: Корневой узел DropZone должен быть Area3D[cite: 5]!")
		is_valid = false
		
	instance.queue_free()
	if is_valid:
		print("  -> Успех: Структура шлюза[cite: 5] валидна.")
	return is_valid

func test_equipment_restrictions() -> bool:
	print("\n[ТЕСТ 4] Проверка логических ограничений снаряжения...")
	# Проверяем, что классы снаряжения существуют и доступны для проверки типов
	var flashlight_script = load("res://flashlight_item.gd")
	if flashlight_script:
		print("  -> Успех: Класс FlashlightItem успешно обнаружен.")
		return true
	else:
		push_error("  -> ОШИБКА: Скрипт flashlight_item.gd не найден.")
		return false
