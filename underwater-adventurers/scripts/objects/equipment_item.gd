extends "res://scripts/objects/physical_item.gd"

@onready var light_node: SpotLight3D = $SpotLight3D

var is_equipped: bool = false
var original_parent: Node3D

func _ready() -> void:
	super._ready()
	self.item_type = ItemType.EQUIPMENT
	self.can_be_grabbed = true
	self.base_value = 0.0
	self.current_value = 0.0
	self.fragility = 1.0  # Снаряжение НЕ ломается
	self.item_name = "Фонарь"
	
	original_parent = get_parent()
	
	if light_node:
		light_node.visible = false

func handle_interact(player: CharacterBody3D) -> void:
	if not is_equipped:
		equip(player)
	else:
		toggle_light()

func handle_drop(player: CharacterBody3D) -> void:
	if is_equipped:
		unequip(player)

func equip(player: CharacterBody3D) -> void:
	is_equipped = true
	
	self.freeze = true
	self.process_mode = Node.PROCESS_MODE_DISABLED
	self.collision_layer = 0
	self.collision_mask = 0
	
	if player.equipment_slot:
		if get_parent():
			get_parent().remove_child(self)
		player.equipment_slot.add_child(self)
		self.position = Vector3.ZERO
		self.rotation = Vector3.ZERO
	
	if light_node:
		light_node.visible = true
	print("🔦 [СНАРЯЖЕНИЕ] Экипировано: ", item_name)

func unequip(player: CharacterBody3D) -> void:
	if not is_equipped:
		return
		
	is_equipped = false
	if light_node:
		light_node.visible = false
	
	if original_parent:
		if get_parent():
			get_parent().remove_child(self)
		original_parent.add_child(self)
		
		self.global_position = player.camera.global_position + (-player.camera.global_basis.z * 1.5) + Vector3(0, 0.5, 0)
		
		self.freeze = false
		self.process_mode = Node.PROCESS_MODE_INHERIT
		self.collision_layer = 1
		self.collision_mask = 1
		
		# ВРЕМЕННАЯ ЗАЩИТА ОТ УРОНА ПОСЛЕ ВЫБРОСА
		self.is_being_dropped = true
		call_deferred("_reset_drop_protection")
		
	print("🔦 [СНАРЯЖЕНИЕ] Выброшено: ", item_name)

func _reset_drop_protection() -> void:
	await get_tree().create_timer(0.5).timeout
	self.is_being_dropped = false

func toggle_light() -> void:
	if light_node:
		light_node.visible = not light_node.visible
		print("💡 [СВЕТ] ", "Включен" if light_node.visible else "Выключен")

func get_perceived_range() -> String:
	return "[СНАРЯЖЕНИЕ] " + item_name + " (Не продаётся)"

func get_exact_value() -> float:
	return 0.0