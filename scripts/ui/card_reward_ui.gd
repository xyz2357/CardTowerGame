extends Control

# 卡牌奖励UI控制器 - 完整修复版
class_name CardRewardUI

var rewards_container: HBoxContainer
var skip_button: Button
var confirm_button: Button
var title_label: Label

var card_ui_scene = preload("res://scenes/card.tscn")
var reward_cards: Array[Dictionary] = []
var selected_card: Dictionary = {}
var selected_card_ui: CardUI = null

signal reward_skipped
signal reward_confirmed(card_data: Dictionary)

func _ready():
	print("CardRewardUI _ready called")
	setup_ui_references()
	connect_signals()
	print("CardRewardUI _ready completed")

func setup_ui_references():
	title_label = $CenterContainer/VBoxContainer/TitleLabel
	rewards_container = $CenterContainer/VBoxContainer/RewardsContainer
	skip_button = $CenterContainer/VBoxContainer/ButtonContainer/SkipButton
	confirm_button = $CenterContainer/VBoxContainer/ButtonContainer/ConfirmButton
	
	print("CardReward UI elements found:")
	print("  - title_label: ", title_label != null)
	print("  - rewards_container: ", rewards_container != null)
	print("  - skip_button: ", skip_button != null)
	print("  - confirm_button: ", confirm_button != null)
	
	# 🔧 更新标题提供使用说明
	if title_label:
		title_label.text = "选择卡牌奖励 (空格=确认 ESC=跳过)"

func connect_signals():
	if skip_button:
		# 🔧 确保信号没有重复连接
		if not skip_button.pressed.is_connected(_on_skip_pressed):
			skip_button.pressed.connect(_on_skip_pressed)
			print("Skip button signal connected")
		else:
			print("Skip button signal already connected")
	else:
		print("ERROR: Skip button not found!")
	
	if confirm_button:
		# 🔧 确保信号没有重复连接
		if not confirm_button.pressed.is_connected(_on_confirm_pressed):
			confirm_button.pressed.connect(_on_confirm_pressed)
			print("Confirm button signal connected")
		else:
			print("Confirm button signal already connected")
	else:
		print("ERROR: Confirm button not found!")

func setup_rewards(cards: Array[Dictionary]):
	print("Setting up rewards with ", cards.size(), " cards")
	reward_cards = cards
	clear_rewards_display()
	
	for card_data in reward_cards:
		create_reward_card_ui(card_data)
	
	# 重置选择状态
	selected_card = {}
	selected_card_ui = null
	if confirm_button:
		confirm_button.disabled = true
		confirm_button.text = "确认选择"
	
	# 🔧 修复UI层级问题
	fix_ui_blocking_issues()
	
	# 🔧 添加调试按钮
	create_debug_buttons()
	
	# 🔧 添加输入事件监听
	set_process_input(true)

# 🔧 新增：修复UI阻挡问题
func fix_ui_blocking_issues():
	print("🔧 Fixing UI blocking issues...")
	
	# 确保所有可能阻挡的元素都不阻挡鼠标事件
	var elements_to_fix = [
		$Background,
		$CenterContainer,
		$CenterContainer/VBoxContainer,
		$CenterContainer/VBoxContainer/RewardsContainer,
		$CenterContainer/VBoxContainer/ButtonContainer
	]
	
	for element in elements_to_fix:
		if element:
			element.mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("Set mouse_filter to IGNORE for: ", element.name)
	
	# 🔧 关键修复：让按钮容器重新接收事件
	var button_container = $CenterContainer/VBoxContainer/ButtonContainer
	if button_container:
		button_container.mouse_filter = Control.MOUSE_FILTER_PASS
		print("Set button container to PASS")
	
	# 🔧 超强化按钮设置
	if skip_button:
		skip_button.mouse_filter = Control.MOUSE_FILTER_PASS
		skip_button.z_index = 2000  # 更高的层级
		skip_button.custom_minimum_size = Vector2(150, 80)  # 更大的按钮
		skip_button.modulate = Color.CYAN
		skip_button.flat = false  # 确保有视觉边框
		
		# 🔧 添加悬停效果
		skip_button.mouse_entered.connect(func():
			print("🖱️ Skip button mouse entered!")
			skip_button.modulate = Color.LIGHT_BLUE
		)
		skip_button.mouse_exited.connect(func():
			print("🖱️ Skip button mouse exited!")
			skip_button.modulate = Color.CYAN
		)
		
		print("Enhanced skip button with hover effects")
	
	if confirm_button:
		confirm_button.mouse_filter = Control.MOUSE_FILTER_PASS
		confirm_button.z_index = 2000  # 更高的层级
		confirm_button.custom_minimum_size = Vector2(150, 80)  # 更大的按钮
		confirm_button.modulate = Color.MAGENTA
		confirm_button.flat = false  # 确保有视觉边框
		
		# 🔧 添加悬停效果
		confirm_button.mouse_entered.connect(func():
			print("🖱️ Confirm button mouse entered!")
			confirm_button.modulate = Color.LIGHT_PINK
		)
		confirm_button.mouse_exited.connect(func():
			print("🖱️ Confirm button mouse exited!")
			confirm_button.modulate = Color.MAGENTA
		)
		
		print("Enhanced confirm button with hover effects")
	
	print("✅ UI blocking issues fixed with enhanced buttons")

func clear_rewards_display():
	if rewards_container:
		for child in rewards_container.get_children():
			child.queue_free()

func create_reward_card_ui(card_data: Dictionary):
	print("Creating reward card UI for: ", card_data.get("name", "Unknown"))
	
	var card_ui = card_ui_scene.instantiate() as CardUI
	rewards_container.add_child(card_ui)
	card_ui.setup_card(card_data)
	
	# 根据稀有度设置边框颜色
	if card_data.has("rarity"):
		var rarity_color = CardRewards.get_rarity_color(card_data.rarity)
		if card_ui.card_background:
			# 添加边框效果
			var border = ColorRect.new()
			border.color = rarity_color
			border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			border.size_flags_vertical = Control.SIZE_EXPAND_FILL
			card_ui.add_child(border)
			card_ui.move_child(border, 0)  # 移到最底层
			
			# 调整现有背景的边距
			if card_ui.card_background:
				card_ui.card_background.position = Vector2(3, 3)
				card_ui.card_background.size = card_ui.size - Vector2(6, 6)
	
	# 🔧 修复信号连接 - 使用lambda表达式来正确处理参数
	card_ui.gui_input.connect(func(event: InputEvent):
		_on_reward_card_clicked(event, card_data, card_ui)
	)
	
	# 禁用拖拽功能
	card_ui.set_interactable(false)
	card_ui.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_reward_card_clicked(event: InputEvent, card_data: Dictionary, card_ui: CardUI):
	print("Reward card clicked: ", card_data.get("name", "Unknown"))
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_card(card_data, card_ui)

func select_card(card_data: Dictionary, card_ui: CardUI):
	print("Selecting reward card: ", card_data.get("name", "Unknown"))
	
	# 取消之前的选择
	if selected_card_ui and is_instance_valid(selected_card_ui):
		selected_card_ui.scale = Vector2.ONE
		selected_card_ui.modulate = Color.WHITE
		print("Deselected previous card")
	
	# 选择新卡牌
	selected_card = card_data
	selected_card_ui = card_ui
	
	# 高亮选中的卡牌
	card_ui.scale = Vector2(1.1, 1.1)
	card_ui.modulate = Color.YELLOW
	
	# 启用确认按钮
	if confirm_button:
		confirm_button.disabled = false
		confirm_button.text = "确认选择: " + card_data.get("name", "Unknown")
		print("Confirm button enabled and text updated")
	else:
		print("ERROR: Confirm button is null!")
	
	print("Selected reward card: ", card_data.name)
	print("Confirm button disabled status: ", confirm_button.disabled if confirm_button else "null")

func _on_skip_pressed():
	print("🔴 SKIP BUTTON PRESSED! (Original)")
	print("  - Current scene: ", get_tree().current_scene)
	print("  - Button parent: ", skip_button.get_parent() if skip_button else "null")
	print("  - UI valid: ", is_instance_valid(self))
	
	# 🔧 防止重复触发
	if skip_button:
		skip_button.disabled = true
	
	print("📡 Emitting reward_skipped signal...")
	reward_skipped.emit()
	
	print("🚪 Calling close_reward_screen...")
	close_reward_screen()

func _on_confirm_pressed():
	print("🟢 CONFIRM BUTTON PRESSED! (Original)")
	print("  - Selected card empty: ", selected_card.is_empty())
	print("  - Selected card: ", selected_card)
	print("  - Current scene: ", get_tree().current_scene)
	print("  - Button parent: ", confirm_button.get_parent() if confirm_button else "null")
	print("  - UI valid: ", is_instance_valid(self))
	
	# 🔧 防止重复触发
	if confirm_button:
		confirm_button.disabled = true
	
	if not selected_card.is_empty():
		print("✅ Confirming reward: ", selected_card.name)
		print("📡 Emitting reward_confirmed signal...")
		reward_confirmed.emit(selected_card)
		print("🚪 Calling close_reward_screen...")
		close_reward_screen()
	else:
		print("❌ No card selected!")
		# 重新启用按钮
		if confirm_button:
			confirm_button.disabled = false

func close_reward_screen():
	print("🚪 CLOSE_REWARD_SCREEN called")
	print("  - UI valid: ", is_instance_valid(self))
	print("  - UI parent: ", get_parent())
	print("  - In tree: ", is_inside_tree())
	
	# 🔧 确保只能关闭一次
	if not is_inside_tree():
		print("⚠️ UI already removed from tree!")
		return
	
	# 🔧 立即移除所有信号连接，防止重复触发
	if skip_button and skip_button.pressed.is_connected(_on_skip_pressed):
		skip_button.pressed.disconnect(_on_skip_pressed)
		print("Disconnected skip button signal")
	
	if confirm_button and confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.disconnect(_on_confirm_pressed)
		print("Disconnected confirm button signal")
	
	print("📄 Queuing UI for deletion...")
	queue_free()
	print("✅ Reward screen close completed")

# 🔧 调试按钮
func create_debug_buttons():
	# 先检查原始按钮的状态
	debug_original_buttons()
	
	# 创建一个大的测试确认按钮
	var debug_confirm = Button.new()
	debug_confirm.text = "调试确认"
	debug_confirm.custom_minimum_size = Vector2(200, 60)
	debug_confirm.position = Vector2(50, 50)
	debug_confirm.modulate = Color.GREEN
	add_child(debug_confirm)
	
	debug_confirm.pressed.connect(func():
		print("🔧 Debug confirm button pressed!")
		if not selected_card.is_empty():
			print("🔧 Debug confirming: ", selected_card.name)
			reward_confirmed.emit(selected_card)
			close_reward_screen()
		else:
			print("🔧 Debug: No card selected")
	)
	
	# 创建一个大的测试跳过按钮
	var debug_skip = Button.new()
	debug_skip.text = "调试跳过"
	debug_skip.custom_minimum_size = Vector2(200, 60)
	debug_skip.position = Vector2(300, 50)
	debug_skip.modulate = Color.RED
	add_child(debug_skip)
	
	debug_skip.pressed.connect(func():
		print("🔧 Debug skip button pressed!")
		reward_skipped.emit()
		close_reward_screen()
	)
	
	print("🔧 Debug buttons created")

# 🔧 新增：全局输入监听
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				print("🔧 SPACE pressed - force confirm!")
				if not selected_card.is_empty():
					print("🔧 Force confirming: ", selected_card.name)
					_on_confirm_pressed()
				else:
					print("🔧 No card selected for space confirm")
			KEY_ESCAPE:
				print("🔧 ESCAPE pressed - force skip!")
				_on_skip_pressed()
			KEY_F5:
				print("🔧 F5 pressed - test original buttons!")
				test_original_buttons()
	
	# 🔧 新增：备用按钮点击检测（类似卡牌的备用检测）
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		print("🔧 Mouse click at: ", mouse_pos)
		
		# 检查是否点击了跳过按钮区域
		if skip_button and is_mouse_in_button_area(mouse_pos, skip_button):
			print("🎯 BACKUP CLICK detected on SKIP button!")
			_on_skip_pressed()
			get_viewport().set_input_as_handled()
			return
		
		# 检查是否点击了确认按钮区域
		if confirm_button and is_mouse_in_button_area(mouse_pos, confirm_button):
			print("🎯 BACKUP CLICK detected on CONFIRM button!")
			_on_confirm_pressed()
			get_viewport().set_input_as_handled()
			return

# 🔧 新增：检查鼠标是否在按钮区域内
func is_mouse_in_button_area(mouse_pos: Vector2, button: Button) -> bool:
	if not button or not is_instance_valid(button):
		return false
	
	var button_rect = Rect2(button.global_position, button.size)
	var in_area = button_rect.has_point(mouse_pos)
	
	if in_area:
		print("  - Mouse in button area: ", button.text)
		print("  - Button rect: ", button_rect)
		print("  - Mouse pos: ", mouse_pos)
	
	return in_area

# 🔧 新增：测试原始按钮
func test_original_buttons():
	print("🔧 Testing original buttons programmatically...")
	
	if skip_button:
		print("🔧 Emitting skip button pressed signal...")
		skip_button.pressed.emit()
	else:
		print("🔧 Skip button is null!")
	
	if confirm_button and not selected_card.is_empty():
		print("🔧 Emitting confirm button pressed signal...")
		confirm_button.pressed.emit()
	else:
		print("🔧 Confirm button is null or no card selected!")

# 🔧 新增：检查原始按钮状态
func debug_original_buttons():
	print("=== 原始按钮调试信息 ===")
	
	if skip_button:
		print("Skip Button:")
		print("  - Visible: ", skip_button.visible)
		print("  - Disabled: ", skip_button.disabled)
		print("  - Position: ", skip_button.position)
		print("  - Size: ", skip_button.size)
		print("  - Global position: ", skip_button.global_position)
		print("  - Mouse filter: ", skip_button.mouse_filter)
		print("  - Z index: ", skip_button.z_index)
		print("  - Text: ", skip_button.text)
		
		# 🔧 更强力的修复
		skip_button.visible = true
		skip_button.disabled = false
		skip_button.mouse_filter = Control.MOUSE_FILTER_PASS
		skip_button.z_index = 1000  # 极高的Z层级
		skip_button.modulate = Color.CYAN
		skip_button.custom_minimum_size = Vector2(100, 50)  # 增大按钮
		
		# 🔧 强制重新连接信号
		if skip_button.pressed.is_connected(_on_skip_pressed):
			skip_button.pressed.disconnect(_on_skip_pressed)
		skip_button.pressed.connect(_on_skip_pressed)
		
		print("  - Skip button SUPER fixed!")
	else:
		print("Skip button is null!")
	
	if confirm_button:
		print("Confirm Button:")
		print("  - Visible: ", confirm_button.visible)
		print("  - Disabled: ", confirm_button.disabled)
		print("  - Position: ", confirm_button.position)
		print("  - Size: ", confirm_button.size)
		print("  - Global position: ", confirm_button.global_position)
		print("  - Mouse filter: ", confirm_button.mouse_filter)
		print("  - Z index: ", confirm_button.z_index)
		print("  - Text: ", confirm_button.text)
		
		# 🔧 更强力的修复
		confirm_button.visible = true
		confirm_button.mouse_filter = Control.MOUSE_FILTER_PASS
		confirm_button.z_index = 1000  # 极高的Z层级
		confirm_button.modulate = Color.MAGENTA
		confirm_button.custom_minimum_size = Vector2(100, 50)  # 增大按钮
		
		# 🔧 强制重新连接信号
		if confirm_button.pressed.is_connected(_on_confirm_pressed):
			confirm_button.pressed.disconnect(_on_confirm_pressed)
		confirm_button.pressed.connect(_on_confirm_pressed)
		
		print("  - Confirm button SUPER fixed!")
	else:
		print("Confirm button is null!")
	
	# 🔧 检查背景是否阻挡事件
	var background = $Background
	if background:
		print("Background found - setting mouse filter to IGNORE")
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	print("=== 调试信息结束 ===")

# 显示卡牌奖励的静态方法
static func show_card_rewards(parent: Node, cards: Array[Dictionary]) -> CardRewardUI:
	var reward_scene = preload("res://scenes/card_reward.tscn")
	var reward_ui = reward_scene.instantiate() as CardRewardUI
	
	if not reward_ui:
		print("ERROR: Failed to instantiate CardRewardUI!")
		return null
	
	print("CardRewardUI instantiated successfully")
	parent.add_child(reward_ui)
	print("CardRewardUI added to parent: ", parent.name)
	
	# 🔧 延迟设置奖励，确保节点已准备好
	reward_ui.call_deferred("setup_rewards", cards)
	
	print("CardRewardUI setup completed")
	return reward_ui
