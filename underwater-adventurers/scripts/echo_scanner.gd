extends RigidBody3D
class_name EchoScanner

@export var item_name: String = "Эхолокатор"
@export var base_real_value: float = 250.0
@export var scan_radius: float = 15.0

# Метод, вызываемый при активации предмета из инвентаря
func activate_scanner(player_camera: Camera3D) -> void:
	print("📡 [ЭХОЛОКАТОР] Импульс запущен...")
	
	# Создаем сферу поиска физических объектов в радиусе scan_radius
	var space_state = player_camera.get_world_3d().direct_space_state
	# Для упрощения имитируем поиск объектов вокруг игрока
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = scan_radius
	query.shape = sphere
	query.transform = player_camera.global_transform
	
	var results = space_state.intersect_shape(query, 32)
	var found_targets = 0
	
	for result in results:
		var collider = result.collider
		if collider and collider != self and not collider is CharacterBody3D:
			found_targets += 1
			var distance = player_camera.global_position.distance_to(collider.global_position)
			
			# Чем дальше объект, тем менее точный сигнал (имитируем нечеткость)
			if distance > (scan_radius * 0.6):
				print("   ~ Слабенький / шумный сигнал вдалеке (~", int(distance), "м). Непонятно: тайник или угроза?")
			else:
				print("   ! Четкий металлический/полостной отклик на дистанции ", int(distance), "м.")
				
	if found_targets == 0:
		print("📡 [ЭХОЛОКАТОР] Тишина... Поблизости нет отражающих поверхностей.")

func get_perceived_range() -> String:
	return "[ТЕХНИКА] Эхолокатор (200 — 300 кр.)"

func get_exact_value() -> float:
	return base_real_value


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
