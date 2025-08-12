extends Control

# 卡牌UI组件 - 只负责显示和交互
class_name CardUI

signal card_played(card_data: Dictionary, card_ui: CardUI)

@export var card_name_label_path: NodePath
@export var cost_label_path: NodePath
@export var description_label_path: NodePath
@export var card_background_path: NodePath

var card_name_label: Label
var cost_label: Label
var description_label: Label
var card_background: Control

var card_data: Dictionary = {}
var is_dragging: bool = false
var original_position: Vector2
var original_parent: Control

const HOVER_SCALE = Vector2(1.1, 1.1)
const NORMAL_SCALE = Vector2(1.0, 1.0)
const DRAG_Z_INDEX = 100

func _ready():
	print("CardUI _ready called")
	setup_ui_references()
	connect_mouse_events()
	
	# 设置卡牌的基本尺寸和可见性
	custom_minimum_size = Vector2(120, 160)
	size = Vector2(120, 160)

func setup_ui_references():
	print("Setting up card UI references...")
	
	if card_name_label_path:
		card_name_label = get_node(card_name_label_path)
		print("Card name label found: ", card_name_label)
	
	if cost_label_path:
		cost_label = get_node(cost_label_path)
		print("Cost label found: ", cost_label)
	
	if description_label_path:
		description_label = get_node(description_label_path)
		print("Description label found: ", description_label)
	
	if card_background_path:
		card_background = get_node(card_background_path)
		print("Card background found: ", card_background)
		if card_background:
			# 确保背景有默认颜色
			if card_background is ColorRect:
				card_background.color = Color.WHITE

func connect_mouse_events():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup_card(data: Dictionary):
	print("Setting up card with data: ", data)
	card_data = data
	update_display()

func update_display():
	print("Updating card display...")
	
	if card_name_label:
		card_name_label.text = card_data.get("name", "未知")
		print("Updated card name: ", card_name_label.text)
	
	if cost_label:
		cost_label.text = str(card_data.get("cost", 0))
		print("Updated cost: ", cost_label.text)
	
	if description_label:
		var desc = generate_description()
		description_label.text = desc
		print("Updated description: ", desc)
	
	update_card_appearance()

func generate_description() -> String:
	var desc = ""
	
	if card_data.has("damage"):
		desc += "造成 %d 点伤害" % card_data.damage
	
	if card_data.has("block"):
		if desc != "":
			desc += "\n"
		desc += "获得 %d 点护甲" % card_data.block
	
	if card_data.has("heal"):
		if desc != "":
			desc += "\n"
		desc += "恢复 %d 点生命" % card_data.heal
	
	if card_data.has("energy"):
		if desc != "":
			desc += "\n"
		desc += "获得 %d 点能量" % card_data.energy
	
	return desc

func update_card_appearance():
	if not card_background:
		print("WARNING: card_background is null")
		return
	
	# 根据卡牌类型设置颜色
	var color = Color.WHITE
	match card_data.get("type", ""):
		"attack":
			color = Color.LIGHT_CORAL
		"skill":
			color = Color.LIGHT_BLUE
		"power":
			color = Color.LIGHT_GREEN
		_:
			color = Color.LIGHT_GRAY
	
	# 确保背景有颜色
	if card_background is ColorRect:
		card_background.color = color
		print("Card background color set to: ", color)
	elif card_background.has_method("set_modulate"):
		card_background.modulate = color
		print("Card background modulate set to: ", color)

func _on_mouse_entered():
	if not is_dragging:
		animate_hover(true)

func _on_mouse_exited():
	if not is_dragging:
		animate_hover(false)

func animate_hover(hover: bool):
	var target_scale = HOVER_SCALE if hover else NORMAL_SCALE
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.1)
	z_index = 10 if hover else 0

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion and is_dragging:
		handle_drag(event)

func handle_mouse_button(event: InputEventMouseButton):
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if event.pressed:
		start_drag()
	else:
		end_drag()

func start_drag():
	print("Starting drag for card: ", card_data.get("name", "Unknown"))
	is_dragging = true
	original_position = position
	original_parent = get_parent()
	z_index = DRAG_Z_INDEX
	
	# 将卡牌移动到顶层以便拖拽
	if get_tree().current_scene:
		reparent(get_tree().current_scene)

func handle_drag(event: InputEventMouseMotion):
	global_position += event.relative

func end_drag():
	if not is_dragging:
		return
	
	print("Ending drag for card: ", card_data.get("name", "Unknown"))
	is_dragging = false
	
	if is_in_play_area():
		print("Card played in play area")
		play_card_action()
	else:
		print("Card returned to hand")
		return_to_hand()

func is_in_play_area() -> bool:
	var viewport = get_viewport()
	if not viewport:
		return false
	
	var viewport_size = viewport.size
	# 如果卡牌被拖到上半部分，认为是要打出
	return global_position.y < viewport_size.y * 0.6

func play_card_action():
	print("Playing card: ", card_data)
	card_played.emit(card_data, self)

func return_to_hand():
	# 返回到原来的父容器
	if original_parent and is_instance_valid(original_parent):
		reparent(original_parent)
		
		var tween = create_tween()
		tween.parallel().tween_property(self, "position", original_position, 0.3)
		tween.parallel().tween_property(self, "scale", NORMAL_SCALE, 0.2)
	
	z_index = 0

func set_interactable(enabled: bool):
	mouse_filter = Control.MOUSE_FILTER_IGNORE if not enabled else Control.MOUSE_FILTER_PASS
