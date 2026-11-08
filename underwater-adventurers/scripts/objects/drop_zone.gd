extends Area3D

@export var zone_name: String = "Главный шлюз сбора"
@export var game_ui_node: CanvasLayer

var total_collected_value: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		# ПРОВЕРКА: Запрещаем сдавать снаряжение
		if body.has_method("get_type") and body.get_type() == body.ItemType.EQUIPMENT:
			print("🚫 [ШЛЮЗ] Отказ: Снаряжение (", body.name, ") не принимается.")
			return

		var exact_value = 0.0
		if body.has_method("get_exact_value"):
			exact_value = body.get_exact_value()
		else:
			exact_value = body.mass * 15.0
		
		if exact_value > 0:
			total_collected_value += exact_value
			if game_ui_node and game_ui_node.has_method("add_score"):
				game_ui_node.add_score(exact_value)
			print("📦 [ШЛЮЗ] Принят предмет: ", body.name, " | Выплата: ", snapped(exact_value, 0.1), " кр.")
		else:
			print("⚠️ [ШЛЮЗ] Предмет ", body.name, " не имеет ценности.")
			
		if body.has_method("on_collected"):
			body.on_collected()
			
		body.queue_free()