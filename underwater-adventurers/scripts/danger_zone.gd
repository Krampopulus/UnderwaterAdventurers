extends Area3D

func _ready() -> void:
	# При старте зона начинает слушать, кто в неё входит
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Проверяем, что вошедший объект состоит в группе "player"
	if body.is_in_group("player"):
		print("⚠️ [DangerZone] Игрок вошёл в опасную зону!")
		# Вызываем глобальную функцию смерти в GameManager
		GameManager.trigger_player_death("Игрок вошёл в опасную зону")