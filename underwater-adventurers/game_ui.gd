extends CanvasLayer

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
