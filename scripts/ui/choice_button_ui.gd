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
	print("ChoiceButtonUI _ready called")
	setup_ui_references()

func setup_ui_references():
	print("Setting up UI references...")
	
	if button_path:
		button = get_node(button_path)
		if button:
			button.pressed.connect(_on_button_pressed)
			print("Button found and connected: ", button)
		else:
			print("ERROR: Button not found at path: ", button_path)
	
	if name_label_path:
		name_label = get_node(name_label_path)
		print("Name label found: ", name_label)
	
	if description_label_path:
		description_label = get_node(description_label_path)
		print("Description label found: ", description_label)

func setup_choice(data: Dictionary):
	print("Setting up choice with data: ", data)
	choice_data = data
	update_display()

func update_display():
	print("Updating display...")
	
	if name_label:
		name_label.text = choice_data.get("name", "未知选择")
		print("Updated name label: ", name_label.text)
	else:
		print("WARNING: name_label is null")
	
	if description_label:
		description_label.text = choice_data.get("description", "")
		print("Updated description label: ", description_label.text)
	else:
		print("WARNING: description_label is null")
	
	update_button_appearance()

func update_button_appearance():
	if not button:
		print("WARNING: button is null in update_button_appearance")
		return
	
	# 根据选择类型设置颜色
	var choice_type = choice_data.get("type", 0)
	print("Choice type: ", choice_type)
	
	match choice_type:
		ChoiceGenerator.ChoiceType.ENEMY:
			button.modulate = Color.LIGHT_CORAL
		ChoiceGenerator.ChoiceType.ELITE:
			button.modulate = Color.DARK_RED
		ChoiceGenerator.ChoiceType.REST:
			button.modulate = Color.LIGHT_GREEN
		ChoiceGenerator.ChoiceType.SHOP:
			button.modulate = Color.GOLD
		ChoiceGenerator.ChoiceType.TREASURE:
			button.modulate = Color.PURPLE
		ChoiceGenerator.ChoiceType.BOSS:
			button.modulate = Color.BLACK
		_:
			button.modulate = Color.WHITE
	
	# 确保按钮有最小尺寸
	if button:
		button.custom_minimum_size = Vector2(200, 80)
		print("Button appearance updated, modulate: ", button.modulate)

func _on_button_pressed():
	print("Button pressed! Choice data: ", choice_data)
	choice_clicked.emit(choice_data)
