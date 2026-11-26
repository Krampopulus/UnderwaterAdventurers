extends "res://scripts/objects/physical_item.gd"

# --- НАСТРОЙКИ СНАРЯЖЕНИЯ ---
@export var equipment_description: String = "Описание предмета"
var is_equipped: bool = false

func _ready() -> void:
	super._ready()
	# Принудительно задаём свойства для снаряжения
	is_equipment = true
	base_price = 0  # Снаряжение не продаётся в зону лута (цена 0)
	current_value = 0

# --- ЛОГИКА ЭКИПИРОВКИ ---
func equip() -> void:
	is_equipped = true
	print("⚙️ [%s] Экипировано!" % item_name)
	# Сюда позже добавим логику: включение фонаря, изменение статов и т.д.

func unequip() -> void:
	is_equipped = false
	print("⚙️ [%s] Снято!" % item_name)
	# Сюда позже добавим логику: выключение фонаря и т.д.

# Переопределяем метод поломки, чтобы снаряжение не исчезало, а просто деактивировалось
func _break_item() -> void:
	is_broken = true
	is_equipped = false
	print("💥 [%s] СЛОМАНО! Требуется ремонт." % item_name)
	item_destroyed.emit()
	
	# Визуал: серый цвет (как у лута)
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		var mat = mesh.get_active_material(0)
		if mat:
			mat.albedo_color = Color(0.3, 0.3, 0.3)