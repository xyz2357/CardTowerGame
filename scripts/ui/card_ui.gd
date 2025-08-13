extends Control

# 修复版卡牌UI - 解决点击无响应问题
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
var is_interactable: bool = true

func _ready():
	print("=== CardUI _ready called ===")
	
	# 基本设置
	custom_minimum_size = Vector2(120, 160)
	size = Vector2(120, 160)
	
	# 🔧 关键修复1：确保鼠标事件可以传递
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
	print("Scene structure:")
	print_node_tree(self, 0)
	
	if card_name_label_path:
		card_name_label = get_node(card_name_label_path)
		print("card_name_label found: ", card_name_label != null, " at path: ", card_name_label_path)
	else:
		print("ERROR: card_name_label_path is empty!")
		
	if cost_label_path:
		cost_label = get_node(cost_label_path)
		print("cost_label found: ", cost_label != null, " at path: ", cost_label_path)
	else:
		print("ERROR: cost_label_path is empty!")
		
	if description_label_path:
		description_label = get_node(description_label_path)
		print("description_label found: ", description_label != null, " at path: ", description_label_path)
	else:
		print("ERROR: description_label_path is empty!")
		
	if card_background_path:
		card_background = get_node(card_background_path)
		print("card_background found: ", card_background != null, " at path: ", card_background_path)
		if card_background:
			# 🔧 确保背景不阻挡事件
			card_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("Background mouse_filter set to IGNORE")
			# 确保所有子元素也不阻挡事件
			set_children_mouse_filter_recursive(card_background, Control.MOUSE_FILTER_IGNORE)
	else:
		print("ERROR: card_background_path is empty!")

# 🔧 新增：打印节点树结构用于调试
func print_node_tree(node: Node, level: int):
	var indent = "  ".repeat(level)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		print_node_tree(child, level + 1)

# 🔧 新增：递归设置子元素的鼠标过滤
func set_children_mouse_filter_recursive(node: Node, filter: int):
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = filter
			print("Set child mouse_filter to IGNORE: ", child.name)
		set_children_mouse_filter_recursive(child, filter)

func connect_signals():
	# 连接基本的鼠标事件
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	print("Basic signals connected")

func setup_card(data: Dictionary):
	print("=== Setting up card: ", data.get("name", "Unknown"), " ===")
	print("Card data received: ", data)
	card_data = data.duplicate()  # 🔧 确保数据完整复制
	
	# 🔧 延迟更新显示，确保所有UI元素都已准备好
	call_deferred("update_display")

func update_display():
	print("=== Updating card display ===")
	print("Card data: ", card_data)
	print("UI elements found:")
	print("  - card_name_label: ", card_name_label != null)
	print("  - cost_label: ", cost_label != null) 
	print("  - description_label: ", description_label != null)
	print("  - card_background: ", card_background != null)
	
	# 🔧 更安全的UI更新
	if card_name_label:
		var card_name = card_data.get("name", "未知卡牌")
		card_name_label.text = card_name
		print("Set card name: ", card_name)
	else:
		print("ERROR: card_name_label is null!")
		
	if cost_label:
		var cost = card_data.get("cost", 0)
		cost_label.text = str(cost)
		print("Set cost: ", cost)
	else:
		print("ERROR: cost_label is null!")
		
	if description_label:
		var desc = generate_description()
		description_label.text = desc
		print("Set description: ", desc)
	else:
		print("ERROR: description_label is null!")
	
	# 🔧 更新外观
	update_card_appearance()
	print("Card display update completed")

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
	print("=== Updating card appearance ===")
	
	if not card_background:
		print("WARNING: card_background is null!")
		return
		
	if not card_background is ColorRect:
		print("WARNING: card_background is not ColorRect, it's: ", card_background.get_class())
		return
	
	var card_type = card_data.get("type", "")
	print("Card type: ", card_type)
	
	var color = Color.LIGHT_GRAY
	match card_type:
		"attack":
			color = Color.LIGHT_CORAL
			print("Set attack color: ", color)
		"skill":
			color = Color.LIGHT_BLUE
			print("Set skill color: ", color)
		"power":
			color = Color.LIGHT_GREEN
			print("Set power color: ", color)
		_:
			print("Unknown card type, using default color: ", color)
	
	card_background.color = color
	print("Background color set to: ", card_background.color)

func _on_mouse_entered():
	if not is_interactable:
		return
		
	print("🖱️ Mouse ENTERED card: ", card_data.get("name", "Unknown"))
	# 简单的悬停效果
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	z_index = 10

func _on_mouse_exited():
	if not is_interactable:
		return
		
	print("🖱️ Mouse EXITED card: ", card_data.get("name", "Unknown"))
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	z_index = 0

func _on_gui_input(event: InputEvent):
	if not is_interactable:
		return
		
	print("🖱️ GUI Input received: ", event, " for card: ", card_data.get("name", "Unknown"))
	
	if event is InputEventMouseButton:
		print("   Mouse button: ", event.button_index, " pressed: ", event.pressed)
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("🎯 LEFT CLICK detected on card: ", card_data.get("name", "Unknown"))
			play_card()
			# 🔧 关键修复4：确保事件被处理
			accept_event()

# 🔧 新增：备用点击检测（通过区域检测）
func _input(event):
	if not is_interactable or not visible or not is_inside_tree():
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 检查鼠标是否在卡牌区域内
		var local_pos = get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, size)
		
		if rect.has_point(local_pos):
			print("🎯 BACKUP CLICK detected on card: ", card_data.get("name", "Unknown"))
			play_card()
			# 🔧 安全地设置输入已处理
			var viewport = get_viewport()
			if viewport:
				viewport.set_input_as_handled()

func play_card():
	if not is_interactable:
		print("❌ Card not interactable: ", card_data.get("name", "Unknown"))
		return
		
	print("🚀 PLAYING CARD: ", card_data.get("name", "Unknown"))
	
	# 🔧 关键修复5：添加音效反馈（可选）
	# AudioManager.play_sound("card_play") # 如果有音效系统
	
	# 视觉反馈
	var original_modulate = modulate
	modulate = Color.YELLOW
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.3)
	
	# 🔧 关键修复6：确保信号发射
	print("📡 Emitting card_played signal...")
	card_played.emit(card_data, self)
	
	# 防止重复点击
	is_interactable = false

func _update_layout():
	# 检查节点是否还在场景树中
	if not is_inside_tree():
		print("Card not in tree, skipping layout update")
		return
	
	# 🔧 关键修复7：确保可见性
	visible = true
	
	# 强制更新布局
	var parent = get_parent()
	if parent:
		parent.queue_sort()
	
	await get_tree().process_frame
	
	print("=== LAYOUT UPDATED ===")
	print("Final position: ", position)
	print("Final global position: ", global_position)
	print("Final size: ", size)
	print("Visible: ", visible)
	print("Modulate: ", modulate)

# 设置交互性
func set_interactable(enabled: bool):
	print("Setting interactable to: ", enabled, " for card: ", card_data.get("name", "Unknown"))
	is_interactable = enabled
	mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	
	# 🔧 视觉反馈
	if enabled:
		modulate = Color.WHITE
	else:
		modulate = Color.GRAY

# 🔧 新增：调试方法
func debug_print_hierarchy():
	print("=== CARD DEBUG INFO ===")
	print("Card name: ", card_data.get("name", "Unknown"))
	print("Position: ", position)
	print("Size: ", size)
	print("Global position: ", global_position)
	print("Visible: ", visible)
	print("Mouse filter: ", mouse_filter)
	print("Is interactable: ", is_interactable)
	print("Z index: ", z_index)
	print("Parent: ", get_parent().name if get_parent() else "None")
	print("Children count: ", get_child_count())
	
	var current = self
	var level = 0
	while current:
		var indent = "  ".repeat(level)
		if current is Control:
			print("%s%s - mouse_filter: %d, visible: %s" % [indent, current.name, current.mouse_filter, current.visible])
		else:
			print("%s%s" % [indent, current.name])
		current = current.get_parent()
		level += 1
		if level > 10:  # 防止无限循环
			break
