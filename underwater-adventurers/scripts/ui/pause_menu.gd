extends Control

# Ссылки на кнопки (пути должны совпадать с тем, что мы создали в Шаге 1)
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
    # КРИТИЧНО: Разрешаем этому узлу работать, даже когда всё дерево игры на паузе
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Скрываем меню при старте игры
    visible = false
    
    # Надёжное подключение сигналов через код (избавляет от ручной настройки в Инспекторе)
    resume_button.pressed.connect(_on_resume_pressed)
    restart_button.pressed.connect(_on_restart_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
    # Ловим нажатие Esc (стандартное действие ui_cancel)
    if event.is_action_pressed("ui_cancel"):
        if get_tree().paused:
            _on_resume_pressed() # Если пауза активна — снимаем её
        else:
            _pause_game()        # Если паузы нет — включаем её

func _pause_game() -> void:
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Освобождаем курсор для кликов
    visible = true

func _on_resume_pressed() -> void:
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Возвращаем захват мыши для управления камерой
    visible = false

func _on_restart_pressed() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene() # Перезагружает текущую сцену (Main.tscn)

func _on_quit_pressed() -> void:
    get_tree().quit() # Закрывает игру