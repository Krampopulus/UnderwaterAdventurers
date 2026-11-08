extends RigidBody3D
class_name StorageReceiver

@export var max_capacity: int = 6 # Вместимость тележки
var stored_items: Array[Node3D] = []

@export var hold_time_required: float = 1.0
var holding_timer: float = 0.0
var player_in_zone: bool = false
var current_player: Node3D = null

@onready var player_detector: Area3D = $PlayerDetector

func _ready() -> void:
	if player_detector:
		player_detector.body_entered.connect(_on_player_entered)
		player_detector.body_exited.connect(_on_player_exited)

func _on_player_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_in_zone = true
		current_player = body
		print("🛒 [ТЕЛЕЖКА] Игрок рядом. Удерживайте E для выгрузки бункера.")

func _on_player_exited(body: Node3D) -> void:
	if body == current_player:
		player_in_zone = false
		current_player = null
		holding_timer = 0.0

func _process(delta: float) -> void:
	if player_in_zone and current_player:
		if Input.is_action_pressed("interact"):
			holding_timer += delta
			if holding_timer >= hold_time_required:
				unload_cart()
				holding_timer = 0.0
		else:
			holding_timer = max(0.0, holding_timer - delta * 2.0)

# Метод загрузки предмета внутрь тележки
func store_item(item: Node3D) -> bool:
	if stored_items.size() < max_capacity:
		stored_items.append(item)
		
		var old_parent = item.get_parent()
		if old_parent:
			old_parent.remove_child(item)
		self.add_child(item) # Привязываем к тележке
		
		if item is RigidBody3D:
			item.freeze = true
			for child in item.get_children():
				if child is CollisionShape3D:
					child.disabled = true
		item.visible = false
		item.process_mode = Node.PROCESS_MODE_DISABLED
		
		print("🛒 [ТЕЛЕЖКА] Предмет загружен. Всего в тележке: ", stored_items.size())
		return true
	else:
		print("⚠️ [ТЕЛЕЖКА] Бункер тележки полон!")
		return false

# Выгрузка содержимого обратно на уровень
func unload_cart() -> void:
	if stored_items.is_empty():
		print("🛒 [ТЕЛЕЖКА] Бункер пуст.")
		return
		
	var current_scene = get_tree().current_scene
	for item in stored_items:
		if item:
			self.remove_child(item)
			current_scene.add_child(item)
			
			item.process_mode = Node.PROCESS_MODE_INHERIT
			item.visible = true
			if item is RigidBody3D:
				item.freeze = false
				for child in item.get_children():
					if child is CollisionShape3D:
						child.disabled = false
						
			item.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5))
			
	stored_items.clear()
	print("🛒 [ТЕЛЕЖКА] Выгрузка завершена. Тележка пуста.")
