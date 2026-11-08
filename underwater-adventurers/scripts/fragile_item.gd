extends RigidBody3D
class_name FragileItem

@export var item_name: String = "Хрупкая ваза"
@export var base_real_value: float = 120.0
@export var impact_threshold: float = 7.0  # Порог скорости удара для поломки
@export var damage_multiplier: float = 0.35 # Множитель стоимости при поломке
@export var shards_scene: PackedScene      # Сцена с осколками (опционально)

var is_broken: bool = false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_impact)

func _on_impact(body: Node) -> void:
	if is_broken:
		return
	if linear_velocity.length() >= impact_threshold:
		break_item()

func break_item() -> void:
	is_broken = true
	base_real_value *= damage_multiplier
	item_name = "Битый осколок (" + item_name + ")"
	print("💥 [ХРУПКОСТЬ] Предмет разбит! Новая стоимость: ", base_real_value)
	
	if shards_scene:
		var shards = shards_scene.instantiate()
		get_parent().add_child(shards)
		shards.global_position = global_position
		
	# Опционально: можно заменить меш на осколки вместо удаления
	# queue_free()

func get_perceived_range() -> String:
	var prefix = "[ХРУПКОЕ] " if not is_broken else "[БИТОЕ] "
	var min_est = base_real_value * 0.8
	var max_est = base_real_value * 1.3
	return prefix + str(int(min_est), " — ", int(max_est), " кр.")

func get_exact_value() -> float:
	return base_real_value
