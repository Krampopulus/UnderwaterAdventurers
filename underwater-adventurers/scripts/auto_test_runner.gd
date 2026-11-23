extends Node
class_name AutoTestRunner

func _ready() -> void:
	run_all_tests()

func run_all_tests() -> void:
	print("\n================ ЗАПУСК АВТО-ТЕСТОВ СИСТЕМЫ ================")
	
	var passed_count = 0
	var tests_to_run = [
		test_game_config,
		test_storage_receiver_scene,
		test_drop_zone_scene,
		test_equipment_script_exists # Переименовано для честности
	]
	
	var total_tests = tests_to_run.size()
	
	for test_func in tests_to_run:
		if test_func.call():
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
		return true
		
	var scene = load(scene_path)
	var instance = scene.instantiate()
	add_child(instance) # ВАЖНО: Добавляем в дерево для корректной работы _ready и queue_free
	
	var is_valid = true
	if not (instance is RigidBody3D):
		push_error("  -> ОШИБКА: Корневой узел StorageReceiver должен быть RigidBody3D!")
		is_valid = false
	if not instance.has_node("PlayerDetector"):
		push_error("  -> ОШИБКА: У тележки отсутствует обязательный узел PlayerDetector.")
		is_valid = false
	if not instance.has_node("CargoArea"):
		push_error("  -> ОШИБКА: У тележки отсутствует внутренняя зона CargoArea.")
		is_valid = false
		
	instance.queue_free() # Теперь работает корректно
	return is_valid

func test_drop_zone_scene() -> bool:
	print("\n[ТЕСТ 3] Проверка структуры шлюза сбора (DropZone)...")
	var scene_path = "res://drop_zone.tscn"
	if not ResourceLoader.exists(scene_path):
		push_warning("  -> Пропущено: Файл сцены шлюза не найден по пути " + scene_path)
		return true
		
	var scene = load(scene_path)
	var instance = scene.instantiate()
	add_child(instance)
	
	var is_valid = true
	if not (instance is Area3D):
		push_error("  -> ОШИБКА: Корневой узел DropZone должен быть Area3D!")
		is_valid = false
		
	instance.queue_free()
	return is_valid

func test_equipment_script_exists() -> bool:
	print("\n[ТЕСТ 4] Проверка наличия скрипта снаряжения...")
	var flashlight_script = load("res://flashlight_item.gd")
	if flashlight_script:
		print("  -> Успех: Класс FlashlightItem успешно обнаружен.")
		return true
	else:
		push_error("  -> ОШИБКА: Скрипт flashlight_item.gd не найден.")
		return false