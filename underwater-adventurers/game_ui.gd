extends CanvasLayer

# Укажи здесь точный путь к твоему Label, если он отличается
@onready var item_label = $Panel/ItemLabel 

# Эту функцию мы будем вызывать из player_controller.gd
func update_equipment_slot(item_name: String):
	if item_name == "" or item_name == "Empty":
		item_label.text = "Слот пуст"
		item_label.modulate.a = 0.5 # Делаем полупрозрачным
	else:
		item_label.text = "В руке: " + item_name
		item_label.modulate.a = 1.0 # Делаем ярким

@onready var score_label: Label = $Control/ScoreLabel
@onready var tooltip_label: Label = $Control/TooltipLabel

var current_score: float = 0.0

func _ready() -> void:
	update_score_display()
	if tooltip_label:
		tooltip_label.text = ""

# Метод для обновления счета (будем вызывать из зоны сбора)
func add_score(amount: float) -> void:
	current_score += amount
	update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Кредиты: " + str(int(current_score)) + " кр."

# Метод для вывода обманчивой оценки предмета под прицелом
func show_item_tooltip(item_name: String, perceived_range: String) -> void:
	if tooltip_label:
		tooltip_label.text = item_name + "\nОценка сканера: " + perceived_range

func hide_item_tooltip() -> void:
	if tooltip_label:
		tooltip_label.text = ""
