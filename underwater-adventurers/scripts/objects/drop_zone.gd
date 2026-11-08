extends Area3D

@export var zone_name: String = "Главный шлюз сбора"
@export var game_ui_node: CanvasLayer # Перетащите сюда узел GameUI в инспекторе Godot

var total_collected_value: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	print("Зона сбора '", zone_name, "' активирована.")

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		var exact_value = 0.0
		
		# Считываем точную стоимость из предмета
		if body.has_method("get_exact_value"):
			exact_value = body.get_exact_value()
		else:
			exact_value = body.mass * 15.0
		
		total_collected_value += exact_value
		
		# Передаем заработанные кредиты в UI
		if game_ui_node and game_ui_node.has_method("add_score"):
			game_ui_node.add_score(exact_value)
			
		print("📦 [ШЛЮЗ] Принят предмет: ", body.name, " | Точная выплата: ", snapped(exact_value, 0.1), " кр.")
		
		if body.has_method("on_collected"):
			body.on_collected()
			
		body.queue_free()
