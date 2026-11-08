extends "res://scripts/objects/physical_item.gd"

@export var legacy_weight: float = 1.0:
	set(val):
		legacy_weight = val
		self.mass = val

@export var legacy_base_real_value: float = 150.0:
	set(val):
		legacy_base_real_value = val
		self.base_value = val

func _ready() -> void:
	super._ready()
	if legacy_weight > 0:
		self.mass = legacy_weight
	if legacy_base_real_value > 0:
		self.base_value = legacy_base_real_value
		self.current_value = legacy_base_real_value

func on_grabbed() -> void:
	pass

func on_released() -> void:
	pass

func on_thrown(impulse: Vector3) -> void:
	apply_central_impulse(impulse)

func on_collected() -> void:
	if is_broken:
		print("⚠️ Предмет ", item_name, " сдан в утиль как лом (0 кр.).")
	else:
		print("✨ Предмет ", item_name, " успешно переработан шлюзом.")