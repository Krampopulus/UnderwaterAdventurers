extends RigidBody3D
class_name FlashlightItem

@export var item_name: String = "Наводный фонарь"
@onready var light_node: SpotLight3D = $SpotLight3D

var is_turned_on: bool = false

func _ready() -> void:
	if light_node:
		light_node.visible = false

# Включение/выключение света по клавише взаимодействия (E)
func activate_flashlight(player_camera: Camera3D) -> void:
	is_turned_on = not is_turned_on
	if light_node:
		light_node.visible = is_turned_on
	print("🔦 [ФОНАРИК] Состояние: ", "Включен" if is_turned_on else "Выключен")

func turn_off_in_hand() -> void:
	if light_node:
		light_node.visible = false

func turn_on_in_hand() -> void:
	if light_node and is_turned_on:
		light_node.visible = true

# У оборудования нет стоимости, поэтому убираем get_perceived_range, чтобы игра не показывала ценник
