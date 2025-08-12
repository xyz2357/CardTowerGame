extends Control

# 简化版卡牌UI - 只保留点击功能
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

func _ready():
	print("=== CardUI _ready called ===")
	
	# 基本设置
	custom_minimum_size = Vector2(120, 160)
	size = Vector2(120, 160)
	
	# 启用交互
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 设置布局标志
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	print("Card size: ", size)
	print("Card mouse_filter: ", mouse_filter)
	
	setup_ui_references()
	connect_signals()
	
	# 延迟布局更新
	call_deferred("_update_layout")

func setup_ui_references():
	print("Setting up UI references...")
	
	if card_name_label_path:
		card_name_label = get_node(card_name_label_path)
	if cost_label_path:
		cost_label = get_node(cost_label_path)
	if description_label_path:
		description_label = get_node(description_label_path)
	if card_background_path:
		card_background = get_node(card_background_path)
		if card_background and card_background is ColorRect:
			# 确保背景不阻挡事件
			card_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("Background mouse_filter set to IGNORE")

func connect_signals():
	# 只连接基本的鼠标事件
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	print("Basic signals connected")

func setup_card(data: Dictionary):
	print("=== Setting up card: ", data.get("name", "Unknown"), " ===")
	card_data = data
	update_display()

func update_display():
	if card_name_label:
		card_name_label.text = card_data.get("name", "未知")
	if cost_label:
		cost_label.text = str(card_data.get("cost", 0))
	if description_label:
		description_label.text = generate_description()
	
	update_card_appearance()
	print("Card display updated for: ", card_data.get("name", "Unknown"))

func generate_description() -> String:
	var desc = ""
	
	if card_data.has("damage"):
		desc += "造成 %d 点伤害" % card_data.damage
	if card_data.has("block"):
		if desc != "": desc += "\n"
		desc += "获得 %d 点护甲" % card_data.block
	if card_data.has("heal"):
		if desc != "": desc += "\n"
		desc += "恢复 %d 点生命" % card_data.heal
	if card_data.has("energy"):
		if desc != "": desc += "\n"
		desc += "获得 %d 点能量" % card_data.energy
	
	return desc

func update_card_appearance():
	if not card_background or not card_background is ColorRect:
		return
	
	var color = Color.LIGHT_GRAY
	match card_data.get("type", ""):
		"attack":
			color = Color.LIGHT_CORAL
		"skill":
			color = Color.LIGHT_BLUE
		"power":
			color = Color.LIGHT_GREEN
	
	card_background.color = color

func _on_mouse_entered():
	print("🖱️ Mouse ENTERED card: ", card_data.get("name", "Unknown"))
	# 简单的悬停效果
	scale = Vector2(1.05, 1.05)
	z_index = 10

func _on_mouse_exited():
	print("🖱️ Mouse EXITED card: ", card_data.get("name", "Unknown"))
	scale = Vector2.ONE
	z_index = 0

func _on_gui_input(event: InputEvent):
	print("🖱️ GUI Input received: ", event, " for card: ", card_data.get("name", "Unknown"))
	
	if event is InputEventMouseButton:
		print("   Mouse button: ", event.button_index, " pressed: ", event.pressed)
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("🎯 LEFT CLICK detected on card: ", card_data.get("name", "Unknown"))
			play_card()

func play_card():
	print("🚀 PLAYING CARD: ", card_data.get("name", "Unknown"))
	
	# 简单的视觉反馈
	var original_modulate = modulate
	modulate = Color.YELLOW
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.3)
	
	# 发射信号
	card_played.emit(card_data, self)

func _update_layout():
	# 检查节点是否还在场景树中
	if not is_inside_tree():
		print("Card not in tree, skipping layout update")
		return
	
	# 强制更新布局
	var parent = get_parent()
	if parent:
		parent.queue_sort()
	
	await get_tree().process_frame
	
	print("=== LAYOUT UPDATED ===")
	print("Final position: ", position)
	print("Final global position: ", global_position)
	print("Final size: ", size)

# 设置交互性
func set_interactable(enabled: bool):
	print("Setting interactable to: ", enabled, " for card: ", card_data.get("name", "Unknown"))
	mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
