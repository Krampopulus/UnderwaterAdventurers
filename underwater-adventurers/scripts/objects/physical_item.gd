extends RigidBody3D

enum ItemType { LOOT, EQUIPMENT }

@export_group("Основные характеристики")
@export var item_name: String = "Неизвестный предмет"
@export var item_type: ItemType = ItemType.LOOT
@export var can_be_grabbed: bool = true

@export_group("Экономика и хрупкость")
@export var base_value: float = 100.0
@export_range(0.0, 1.0) var fragility: float = 1.0
@export var damage_per_hit: float = 0.25

var current_value: float = 0.0
var is_broken: bool = false
var last_damage_time: float = 0.0
var prev_speed: float = 0.0
var is_being_dropped: bool = false  # НОВОЕ: защита от урона при выбросе

@export_group("Визуализация поломки (опционально)")
@export var shards_scene: PackedScene

func _ready() -> void:
	current_value = base_value
	prev_speed = 0.0
	is_being_dropped = false
	
	self.contact_monitor = true
	self.max_contacts_reported = 5
	self.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_broken and fragility < 1.0 and not self.freeze and not is_being_dropped:
		var current_speed = linear_velocity.length()
		
		if prev_speed > 5.0 and current_speed < prev_speed * 0.3:
			var impact_force = prev_speed - current_speed
			if impact_force > 3.0:
				take_damage(impact_force)
		
		prev_speed = current_speed

func _on_body_entered(body: Node) -> void:
	if is_broken or fragility >= 1.0 or self.freeze or is_being_dropped:
		return
	
	var impact_speed = linear_velocity.length()
	
	if Time.get_ticks_msec() - last_damage_time < 500:
		return
	
	if impact_speed > 3.0:
		take_damage(impact_speed)

func take_damage(amount: float) -> void:
	# Защита от спама урона (кулдаун 500мс)
	if Time.get_ticks_msec() - last_damage_time < 500:
		return
	
	last_damage_time = Time.get_ticks_msec()
	
	# Временно размораживаем предмет для регистрации физического столкновения
	var was_frozen = freeze
	if was_frozen:
		freeze = false
		# Микро-толчок, чтобы физический движок "проснулся"
		apply_central_impulse(Vector3.UP * 1.5)
	
	# Наносим урон и снижаем стоимость
	current_value -= amount
	if current_value < 0:
		current_value = 0
	
	# Возвращаем заморозку, если предмет не был в свободном падении
	if was_frozen and not is_being_dropped:
		freeze = true
		collision_layer = 0
	
	# Проверяем, не уничтожен ли предмет
	if current_value <= 0:
		print("💥 Предмет уничтожен: ", item_name)
		# Здесь можно добавить эффект поломки (частицы, звук)
		queue_free()  # Уничтожаем предмет

func _break() -> void:
	is_broken = true
	current_value = 0.0
	print("💥 [ПРЕДМЕТ] ", item_name, " полностью уничтожен!")
	
	if shards_scene:
		var shards = shards_scene.instantiate()
		get_parent().add_child(shards)
		shards.global_position = global_position
	
	for child in get_children():
		if child is MeshInstance3D or child is CSGShape3D:
			child.visible = false

func get_value() -> float:
	return current_value

func can_grab() -> bool:
	return can_be_grabbed and not is_broken

func get_type() -> ItemType:
	return item_type

func get_perceived_range() -> String:
	if is_broken:
		return "[УНИЧТОЖЕНО] " + item_name + " (0 кр.)"
	var min_est = current_value * 0.8
	var max_est = current_value * 1.2
	var prefix = "[ХРУПКОЕ] " if fragility < 1.0 else ""
	return prefix + item_name + " (~" + str(int(min_est)) + " - " + str(int(max_est)) + " кр.)"

func get_exact_value() -> float:
	return current_value