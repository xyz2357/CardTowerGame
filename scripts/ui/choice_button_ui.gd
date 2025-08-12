extends Control

# 选择按钮UI组件 - 只负责显示和交互
class_name ChoiceButtonUI

@export var button_path: NodePath
@export var name_label_path: NodePath
@export var description_label_path: NodePath

var button: Button
var name_label: Label
var description_label: Label

var choice_data: Dictionary = {}

signal choice_clicked(choice_data: Dictionary)

func _ready():
	setup_ui_references()

func setup_ui_references():
	if button_path:
		button = get_node(button_path)
		button.pressed.connect(_on_button_pressed)
	
	if name_label_path:
		name_label = get_node(name_label_path)
	
	if description_label_path:
		description_label = get_node(description_label_path)

func setup_choice(data: Dictionary):
	choice_data = data
	update_display()

func update_display():
	if name_label:
		name_label.text = choice_data.get("name", "未知选择")
	
	if description_label:
		description_label.text = choice_data.get("description", "")
	
	update_button_appearance()

func update_button_appearance():
	if not button:
		return
	
	# 根据选择类型设置颜色
	var choice_type = choice_data.get("type", 0)
	match choice_type:
		ChoiceGenerator.ChoiceType.ENEMY:
			button.modulate = Color.RED
		ChoiceGenerator.ChoiceType.ELITE:
			button.modulate = Color.DARK_RED
		ChoiceGenerator.ChoiceType.REST:
			button.modulate = Color.GREEN
		ChoiceGenerator.ChoiceType.SHOP:
			button.modulate = Color.GOLD
		ChoiceGenerator.ChoiceType.TREASURE:
			button.modulate = Color.PURPLE
		ChoiceGenerator.ChoiceType.BOSS:
			button.modulate = Color.BLACK

func _on_button_pressed():
	choice_clicked.emit(choice_data)
