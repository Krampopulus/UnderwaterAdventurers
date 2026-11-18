extends CanvasLayer

@onready var score_label: Label = $Control/ScoreLabel
@onready var tooltip_label: Label = $Control/TooltipLabel
@export var item_label: Label
@onready var slot1: Label = $Panel/Slot1
@onready var slot2: Label = $Panel/Slot2
@onready var slot3: Label = $Panel/Slot3
@onready var slot4: Label = $Panel/Slot4

var current_score: float = 0.0
var slots_array: Array = []
var equipped_item: RigidBody3D = null

func _ready() -> void:
	update_score_display()
	if tooltip_label:
		tooltip_label.text = ""
	slots_array = [slot1, slot2, slot3, slot4]
	for slot in slots_array:
		if slot:
			slot.text = "Пусто"
			slot.modulate.a = 0.5

func add_score(amount: float) -> void:
	current_score += amount
	update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Кредиты: " + str(int(current_score)) + " кр."

func show_item_tooltip(item_name: String, perceived_range: String) -> void:
	if tooltip_label:
		tooltip_label.text = item_name + "\nОценка сканера: " + perceived_range

func hide_item_tooltip() -> void:
	if tooltip_label:
		tooltip_label.text = ""

func update_equipment_slot(item_name: String) -> void:
	print("🎨 UI: update_equipment_slot(", item_name, ")")
	if item_label == null:
		print("❌ item_label = null!")
		return
	if item_name == "" or item_name == null:
		item_label.text = "Рука: Пусто"
		item_label.modulate.a = 0.5
	else:
		item_label.text = "Рука: " + str(item_name)
		item_label.modulate.a = 1.0

func update_inventory_ui(inventory_data: Array, active_slot: int, equipped: RigidBody3D = null) -> void:
	equipped_item = equipped

	if inventory_data.size() < 4:
		return

	if slots_array.size() < 4:
		slots_array = [slot1, slot2, slot3, slot4]
	if slots_array[0] == null:
		return

	for i in range(4):
		var slot_node = slots_array[i]
		if slot_node == null:
			continue

		var item = inventory_data[i]

		if item != null:
			# ИСПРАВЛЕНО: безопасное получение имени
			var raw_name = item.get("item_name")
			var display_name = raw_name if raw_name != null else item.name
			slot_node.text = str(i + 1) + ": " + str(display_name)
		else:
			slot_node.text = str(i + 1) + ": Пусто"

		if i == active_slot:
			slot_node.modulate = Color(1, 1, 0, 1)
			slot_node.scale = Vector2(1.1, 1.1)
		else:
			slot_node.modulate = Color(1, 1, 1, 0.7)
			slot_node.scale = Vector2(1, 1)

	if item_label != null:
		if equipped_item != null:
			# ИСПРАВЛЕНО: безопасное получение имени
			var raw_name = equipped_item.get("item_name")
			var equip_name = raw_name if raw_name != null else equipped_item.name
			item_label.text = "Рука: " + str(equip_name)
			item_label.modulate.a = 1.0
		else:
			item_label.text = "Рука: Пусто"
			item_label.modulate.a = 0.5