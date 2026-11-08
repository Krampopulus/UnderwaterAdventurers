class_name LootItem
extends RigidBody3D

@export_category("Loot Parameters")
@export var item_id: String = "default_item"
@export var weight: float = 1.0        
@export var is_fake: bool = false  

@export_category("Loot Settings")
@export var item_name: String = "Неизвестный артефакт"
@export var base_real_value: float = 150.0  # Точная стоимость для шлюза

# Гейдизайн: градация ценников (например, 5–10 уровней редкости)
@export_enum("Мусор (1-уровень)", "Обычный (2-уровень)", "Ценный (3-уровень)", "Редкий (4-уровень)", "Легендарный (5-уровень)") 
var tier: int = 0

# Метод для шлюза (возвращает точную стоимость при сдаче)
func get_exact_value() -> float:
	if is_fake:
		return 0.0
	return base_real_value

# Метод для сканера игрока: генерирует «обманчивый» диапазон оценки
func get_perceived_range() -> String:
	if is_fake:
		return "0 — 15 кр. (Подделка?)"
		
	# Имитируем погрешность сканера: диапазон может сдвигаться вниз или вверх от реальной цены
	var error_margin = 0.35 # погрешность 35%
	var min_est = max(10.0, base_real_value * (1.0 - error_margin))
	var max_est = base_real_value * (1.0 + error_margin * 1.5)
	
	return str(int(min_est), " — ", int(max_est), " кр.")

# Хуки для анимаций / эффектов при взаимодействии с игроком
func on_grabbed() -> void:
	# Здесь можно включить подсветку предмета или звук захвата
	pass

func on_released() -> void:
	pass

func on_thrown(impulse: Vector3) -> void:
	apply_central_impulse(impulse)

func on_collected() -> void:
	# Здесь можно воспроизвести звук успешной сдачи в шлюз перед удалением объекта
	print("✨ Предмет ", item_name, " успешно переработан шлюзом.")
