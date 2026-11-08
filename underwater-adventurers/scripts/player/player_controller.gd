extends CharacterBody3D

@export_category("Movement Settings")
@export var max_speed: float = 5.0
@export var acceleration: float = 4.0
@export var deceleration: float = 3.0
@export var mouse_sensitivity: float = 0.003

@export_category("Vacuum & UI Settings")
@export var max_lift_mass: float = 10.0
@export var base_throw_force: float = 12.0
@export var max_charge_time: float = 1.5
@export var game_ui_reference: CanvasLayer

@export var min_hold_distance: float = 1.5
@export var max_hold_distance: float = 5.0
@export var current_hold_distance: float = 2.5
@export var zoom_speed: float = 0.5

@onready var camera: Camera3D = $Camera3D
@onready var equipment_slot: Marker3D = $Camera3D/EquipmentSlot # НОВЫЙ СЛОТ
@onready var vacuum_ray: RayCast3D = $Camera3D/VacuumRay
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D

var held_object: RigidBody3D = null
var equipped_item: RigidBody3D = null # Предмет в слоте
var current_charge_time: float = 0.0
var is_charging_throw: bool = false

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

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if held_object == null:
			try_grab_object()
		else:
			release_held_object()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_hold_distance = clamp(current_hold_distance - zoom_speed, min_hold_distance, max_hold_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_hold_distance = clamp(current_hold_distance + zoom_speed, min_hold_distance, max_hold_distance)

	# КЛАВИША E: Экипировка / Использование
	if event.is_action_pressed("interact"):
		if held_object != null and held_object.has_method("handle_interact"):
			# Сначала освобождаем из манипулятора, чтобы физика не конфликтовала
			var item_to_equip = held_object
			release_held_object()
			item_to_equip.handle_interact(self)
			equipped_item = item_to_equip
		elif equipped_item != null and equipped_item.has_method("handle_interact"):
			equipped_item.handle_interact(self)

		# КЛАВИША Q: Снять снаряжение из слота
	if event.is_action_pressed("drop_equipment"):
		if equipped_item != null and equipped_item.has_method("handle_drop"):
			equipped_item.handle_drop(self) # <-- добавлен self
			equipped_item = null

	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		toggle_flashlight()

func _physics_process(delta: float) -> void:
	if not camera:
		return

	check_raycast_tooltip()

	if held_object != null:
		var target_pos = camera.global_position + (-camera.global_basis.z * current_hold_distance)
		var to_target = target_pos - held_object.global_position
		var distance = to_target.length()
		
		if distance > 3.5: # Немного увеличил лимит для стабильности
			print("⛓️ [ОБРЫВ] Трос натянут слишком сильно. Предмет отпущен.")
			release_held_object()
			return
		
		if held_object.mass <= max_lift_mass:
			held_object.freeze = false
			held_object.angular_damp = 5.0
			held_object.linear_velocity = to_target * 10.0
		else:
			# ТЯЖЕЛЫЙ ПРЕДМЕТ: Строго горизонтальное перемещение
			held_object.freeze = false
			held_object.angular_damp = 10.0
			
			# ПРИНУДИТЕЛЬНО ГАСИМ ВЕРТИКАЛЬНУЮ СКОРОСТЬ (запрет на подъем)
			held_object.linear_velocity.y = min(held_object.linear_velocity.y, 0.0)
			
			# Сила применяется только по горизонтали (X и Z)
			var horizontal_target = Vector3(target_pos.x, held_object.global_position.y, target_pos.z)
			var to_target_horiz = horizontal_target - held_object.global_position
			var pull_force = to_target_horiz.normalized() * (held_object.mass * 25.0)
			held_object.apply_central_force(pull_force)
		
		handle_throw_logic(delta)

	var current_max_speed = max_speed
	if held_object != null:
		var weight_factor = clamp(0.05 + (held_object.mass * 0.035), 0.0, 0.85)
		current_max_speed = max_speed * (1.0 - weight_factor)

	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input_dir -= camera.global_transform.basis.z
	if Input.is_action_pressed("move_backward"): input_dir += camera.global_transform.basis.z
	if Input.is_action_pressed("move_left"): input_dir -= camera.global_transform.basis.x
	if Input.is_action_pressed("move_right"): input_dir += camera.global_transform.basis.x
	if Input.is_action_pressed("move_up"): input_dir += Vector3.UP
	if Input.is_action_pressed("move_down"): input_dir += Vector3.DOWN

	input_dir = input_dir.normalized()
	var target_dir_velocity = input_dir * current_max_speed
	
	if input_dir.length() > 0:
		velocity = velocity.move_toward(target_dir_velocity, acceleration * delta * max_speed)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, deceleration * delta * max_speed)

	move_and_slide()

func try_grab_object() -> void:
	if vacuum_ray.is_colliding():
		var collider = vacuum_ray.get_collider()
		if collider is RigidBody3D:
			var is_grabbable = true
			if collider.has_method("can_grab"):
				is_grabbable = collider.can_grab()
			
			if is_grabbable:
				held_object = collider
				held_object.add_collision_exception_with(self)
				print("✅ Захвачен: ", held_object.name, " (Масса: ", held_object.mass, " кг)")
				if held_object.has_method("on_grabbed"):
					held_object.on_grabbed()

func release_held_object() -> void:
	if held_object != null:
		held_object.remove_collision_exception_with(self)
		held_object.freeze = false
		held_object.angular_damp = 0.1
		
		if held_object.has_method("on_released"):
			held_object.on_released()
			
		held_object = null
		is_charging_throw = false
		current_charge_time = 0.0

func check_raycast_tooltip() -> void:
	if held_object == null and equipped_item == null and vacuum_ray.is_colliding():
		var collider = vacuum_ray.get_collider()
		if collider and collider.has_method("get_perceived_range"):
			var item_name = collider.item_name if "item_name" in collider else "Неизвестный предмет"
			if game_ui_reference and game_ui_reference.has_method("show_item_tooltip"):
				game_ui_reference.show_item_tooltip(item_name, collider.get_perceived_range())
			return
	if game_ui_reference and game_ui_reference.has_method("hide_item_tooltip"):
		game_ui_reference.hide_item_tooltip()

func toggle_flashlight() -> void:
	if flashlight:
		flashlight.visible = not flashlight.visible

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

func execute_throw() -> void:
	if held_object == null: return
	var charge_factor = current_charge_time / max_charge_time
	var throw_dir = -camera.global_transform.basis.z
	var item_weight = max(held_object.mass * 0.5, 1.0)
	var final_impulse = throw_dir * base_throw_force * (1.0 + charge_factor * 1.5) * item_weight
	
	held_object.freeze = false
	if held_object.has_method("on_thrown"):
		held_object.on_thrown(final_impulse)
	else:
		held_object.apply_central_impulse(final_impulse)
		
	release_held_object()
