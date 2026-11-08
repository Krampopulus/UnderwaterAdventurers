extends CharacterBody3D

@export_category("Movement Settings")
@export var max_speed: float = 5.0
@export var acceleration: float = 4.0
@export var deceleration: float = 3.0
@export var mouse_sensitivity: float = 0.003

@export_category("Vacuum & UI Settings")
@export var max_lift_mass: float = 10.0       # Предел для подъема в воздух (до 10 кг)
@export var base_throw_force: float = 12.0   # Базовая сила броска
@export var max_charge_time: float = 1.5     # Максимальное время заряда броска
@export var game_ui_reference: CanvasLayer   # Перетащите сюда узел GameUI в инспекторе Godot
@export var held_object_network_id: int = 0

@onready var camera: Camera3D = $Camera3D
@onready var vacuum_ray: RayCast3D = $Camera3D/VacuumRay
@onready var hold_point: Marker3D = $Camera3D/HoldPoint
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D

var held_object: RigidBody3D = null
var current_charge_time: float = 0.0
var is_charging_throw: bool = false
var print_timer: float = 0.0

func _ready() -> void:
	if not camera:
		for child in get_children():
			if child is Camera3D:
				camera = child
				break
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if not camera:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# ЛКМ: захват или мягкий сброс
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if held_object == null:
			try_grab_object()
		else:
			release_held_object()

	# Клавиша F: включение / выключение подводного фонаря
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		toggle_flashlight()

func _physics_process(delta: float) -> void:
	if not camera:
		return

	# Проверяем предмет под прицелом для сканера UI
	check_raycast_tooltip()

	# Обработка удерживаемого / буксируемого предмета с учётом коллизий
	if held_object != null:
		if held_object.mass <= max_lift_mass:
			held_object.freeze = false
			var to_target = hold_point.global_position - held_object.global_position
			held_object.linear_velocity = to_target * 15.0
			held_object.angular_velocity = held_object.angular_velocity * 0.9
		else:
			held_object.freeze = false
			var pull_dir = (hold_point.global_position - held_object.global_position)
			held_object.apply_central_force(pull_dir * 150.0)
		
		handle_throw_logic(delta)

	# Расчет замедления игрока от веса предмета
	var current_max_speed = max_speed
	if held_object != null:
		var base_penalty = 0.05
		var weight_factor = clamp(base_penalty + (held_object.mass * 0.035), 0.0, 0.75)
		current_max_speed = max_speed * (1.0 - weight_factor)

	# Вывод скорости в консоль
	print_timer += delta
	if print_timer >= 0.5:
		print_timer = 0.0
		var obj_name = held_object.name if held_object != null else "Нет"
		print("Объект: ", obj_name, " | Скорость игрока: ", snapped(velocity.length(), 0.01), " / Макс: ", snapped(current_max_speed, 0.01))

	# Движение игрока
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= camera.global_transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_dir += camera.global_transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= camera.global_transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += camera.global_transform.basis.x
	
	if Input.is_action_pressed("move_up"):
		input_dir += Vector3.UP
	if Input.is_action_pressed("move_down"):
		input_dir += Vector3.DOWN

	input_dir = input_dir.normalized()

	var target_dir_velocity = input_dir * current_max_speed
	if input_dir.length() > 0:
		velocity = velocity.move_toward(target_dir_velocity, acceleration * delta * max_speed)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, deceleration * delta * max_speed)

	move_and_slide()

# Попытка захватить предмет
func try_grab_object() -> void:
	if vacuum_ray.is_colliding():
		var collider = vacuum_ray.get_collider()
		if collider is RigidBody3D:
			held_object = collider
			print("Захвачен объект: ", held_object.name, " (Масса: ", held_object.mass, " кг)")
				
			if held_object.has_method("on_grabbed"):
				held_object.on_grabbed()

# Мягкий сброс предмета
func release_held_object() -> void:
	if held_object != null:
		held_object.freeze = false
		if held_object.has_method("on_released"):
			held_object.on_released()
			
		held_object = null
		is_charging_throw = false
		current_charge_time = 0.0

# Проверка луча для вывода сканера на экран
func check_raycast_tooltip() -> void:
	if vacuum_ray.is_colliding():
		var collider = vacuum_ray.get_collider()
		if collider and collider.has_method("get_perceived_range"):
			var item_name = collider.item_name if "item_name" in collider else "Неизвестный предмет"
			var fake_range = collider.get_perceived_range()
			
			if game_ui_reference and game_ui_reference.has_method("show_item_tooltip"):
				game_ui_reference.show_item_tooltip(item_name, fake_range)
			return
			
	if game_ui_reference and game_ui_reference.has_method("hide_item_tooltip"):
		game_ui_reference.hide_item_tooltip()

# Переключение состояния фонаря
func toggle_flashlight() -> void:
	if flashlight:
		flashlight.visible = not flashlight.visible
		print("Фонарь: ", "Включен" if flashlight.visible else "Выключен")

@rpc("authority")
func sync_held_object(object_id: int) -> void:
	held_object_network_id = object_id
	# Здесь будет логика обновления held_object по ID

# Логика заряда броска на ПКМ
func handle_throw_logic(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if held_object != null and held_object.mass > max_lift_mass:
			return
			
		if not is_charging_throw:
			is_charging_throw = true
			current_charge_time = 0.0
			
		current_charge_time = min(current_charge_time + delta, max_charge_time)
	elif is_charging_throw:
		execute_throw()

# Выполнение физического броска
func execute_throw() -> void:
	if held_object == null:
		return
		
	var charge_factor = current_charge_time / max_charge_time
	var throw_dir = -camera.global_transform.basis.z
	var item_weight = max(held_object.mass * 0.5, 1.0)
	
	var final_impulse = throw_dir * base_throw_force * (1.0 + charge_factor * 1.5) * item_weight
	
	held_object.freeze = false
	if held_object.has_method("on_thrown"):
		held_object.on_thrown(final_impulse)
	else:
		held_object.apply_central_impulse(final_impulse)
		
	held_object = null
	is_charging_throw = false
	current_charge_time = 0.0

