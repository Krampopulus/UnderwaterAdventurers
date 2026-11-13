extends CanvasLayer

@onready var score_label = $Control/ScoreLabel
@onready var tooltip_label = $Control/TooltipLabel
@onready var item_label = $Panel/ItemLabel

@onready var slot1 = $Panel/Slot1
@onready var slot2 = $Panel/Slot2
@onready var slot3 = $Panel/Slot3
@onready var slot4 = $Panel/Slot4

var slots_array: Array = []

# ЕДИНСТВЕННАЯ ФУНКЦИЯ _ready()
func _ready() -> void:
	update_score_display()
	if tooltip_label:
		tooltip_label.text = ""
	
	slots_array = [slot1, slot2, slot3, slot4]
	for slot in slots_array:
		if slot:
			slot.text = "Пусто"
			slot.modulate.a = 0.5

# --- СТАРЫЕ ФУНКЦИИ ---
func show_item_tooltip(item_name: String, perceived_range: String) -> void:
	if tooltip_label:
		tooltip_label.text = item_name + "\nОценка сканера: " + perceived_range

func hide_item_tooltip() -> void:
	if tooltip_label:
		tooltip_label.text = ""

func update_score_display() -> void:
	# Твой старый код обновления счёта (если был)
	pass

# --- ФУНКЦИЯ ДЛЯ ОТОБРАЖЕНИЯ ПРЕДМЕТА В РУКЕ ---
func update_equipment_slot(item_name: String) -> void:
	if item_label == null: return
	if item_name == "" or item_name == null:
		item_label.text = "Слот пуст"
		item_label.modulate.a = 0.5
	else:
		item_label.text = "В руке: " + str(item_name)
		item_label.modulate.a = 1.0

# --- НОВАЯ ФУНКЦИЯ ДЛЯ ИНВЕНТАРЯ ---
func update_inventory_ui(inventory_data: Array, active_slot: int) -> void:
	for i in range(4):
		var slot_node = slots_array[i]
		if slot_node == null: continue
		
		var item = inventory_data[i]
		if item != null:
			var name = item.get("item_name") if "item_name" in item else item.name
			slot_node.text = str(i + 1) + ": " + str(name)
		else:
			slot_node.text = str(i + 1) + ": Пусто"
		
		if i == active_slot:
			slot_node.modulate = Color(1, 1, 0, 1)
			slot_node.scale = Vector2(1.1, 1.1)
		else:
			slot_node.modulate = Color(1, 1, 1, 0.7)
			slot_node.scale = Vector2(1, 1)
