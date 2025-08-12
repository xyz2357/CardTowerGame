extends Control

# 爬塔UI控制器 - 只负责UI展示
class_name TowerUI

@export var floor_label_path: NodePath
@export var player_info_path: NodePath
@export var choices_container_path: NodePath

var floor_label: Label
var player_info: Label
var choices_container: Container

var tower_controller: TowerController
var choice_button_scene = preload("res://scenes/choice_button.tscn")
var active_choice_buttons: Array[ChoiceButtonUI] = []

signal choice_selected(choice_data: Dictionary)

func _ready():
	setup_ui_references()
	create_tower_controller()
	connect_signals()

func setup_ui_references():
	if floor_label_path:
		floor_label = get_node(floor_label_path)
	if player_info_path:
		player_info = get_node(player_info_path)
	if choices_container_path:
		choices_container = get_node(choices_container_path)

func create_tower_controller():
	tower_controller = TowerController.new()
	add_child(tower_controller)

func connect_signals():
	# 连接控制器信号
	tower_controller.ui_update_requested.connect(_on_ui_update_requested)
	tower_controller.choices_update_requested.connect(_on_choices_update_requested)
	tower_controller.message_requested.connect(_on_message_requested)
	tower_controller.battle_requested.connect(_on_battle_requested)
	
	# 连接UI信号到控制器
	choice_selected.connect(tower_controller.handle_choice_selected)

func _on_ui_update_requested(data: Dictionary):
	update_ui_display(data)

func update_ui_display(data: Dictionary):
	if floor_label:
		floor_label.text = "第 %d 层 / %d 层" % [data.current_floor, data.max_floor]
	
	if player_info:
		player_info.text = "生命: %d/%d" % [data.player_hp, data.player_max_hp]

func _on_choices_update_requested(choices: Array):
	update_choices_display(choices)

func update_choices_display(choices: Array):
	clear_choices_display()
	
	for choice_data in choices:
		create_choice_button(choice_data)

func clear_choices_display():
	for button in active_choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	active_choice_buttons.clear()

func create_choice_button(choice_data: Dictionary):
	if not choices_container or not choice_button_scene:
		return
	
	var button_ui = choice_button_scene.instantiate() as ChoiceButtonUI
	choices_container.add_child(button_ui)
	button_ui.setup_choice(choice_data)
	button_ui.choice_clicked.connect(_on_choice_button_clicked)
	
	active_choice_buttons.append(button_ui)

func _on_choice_button_clicked(choice_data: Dictionary):
	choice_selected.emit(choice_data)

func _on_message_requested(message: String):
	show_message(message)

func _on_battle_requested(enemy_data: Dictionary):
	# 切换到战斗场景
	SceneManager.load_battle_scene(enemy_data)

# 简化的消息显示
var current_dialog: AcceptDialog = null

func show_message(text: String):
	if current_dialog and is_instance_valid(current_dialog):
		current_dialog.queue_free()
	
	current_dialog = AcceptDialog.new()
	current_dialog.dialog_text = text
	add_child(current_dialog)
	current_dialog.popup_centered()
func _cleanup_dialog():
	if current_dialog and is_instance_valid(current_dialog):
		current_dialog.queue_free()
		current_dialog = null
