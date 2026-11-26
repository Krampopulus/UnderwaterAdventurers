extends RigidBody3D

# --- НАСТРОЙКИ ПРЕДМЕТА (задаются в инспекторе) ---
@export var item_name: String = "Предмет"
@export var base_price: int = 100
@export var weight: float = 10.0
@export var fragility: float = 0.0          # 0 = не ломается, >0 = множитель урона
@export var is_equipment: bool = false

# --- ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ---
var current_health: float = 100.0
var current_value: int = 0
var is_broken: bool = false

signal item_damaged(new_value: int)
signal item_destroyed()

func _ready() -> void:
	current_value = base_price
	# Слушаем столкновения с другими телами
	contact_monitor = true
	max_contacts_reported = 5
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_broken or fragility == 0.0:
		return  # Не ломается — выходим
	
	# Сила удара = скорость предмета в момент столкновения
	var impact_force = linear_velocity.length()
	
	# Порог: мелкие толчки (< 3 м/с) не считаются ударом
	if impact_force < 3.0:
		return
	
	# Урон = сила × хрупкость
	var damage = impact_force * fragility
	current_health -= damage
	
	# Пересчитываем цену
	current_value = int(base_price * max(0.0, current_health / 100.0))
	
	if current_health <= 0:
		_break_item()
	else:
		item_damaged.emit(current_value)
		print("🔸 [%s] Удар! Сила: %.1f, Здоровье: %.0f, Цена: %d" % 
			  [item_name, impact_force, current_health, current_value])

func _break_item() -> void:
	is_broken = true
	current_value = 0
	current_health = 0
	print("💥 [%s] СЛОМАЛСЯ! Потеряно: %d кредитов" % [item_name, base_price])
	item_destroyed.emit()
	
	# Визуал: серый цвет
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		var mat = mesh.get_active_material(0)
		if mat:
			mat.albedo_color = Color(0.3, 0.3, 0.3)
	
	# Исчезает через 2 секунды
	await get_tree().create_timer(2.0).timeout
	queue_free()