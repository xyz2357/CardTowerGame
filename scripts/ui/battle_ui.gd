extends Control

# 战斗UI控制器 - 完整修复版
class_name BattleUI

@export var player_hp_label_path: NodePath
@export var enemy_hp_label_path: NodePath
@export var player_energy_label_path: NodePath
@export var hand_container_path: NodePath
@export var battle_log_path: NodePath
@export var end_turn_button_path: NodePath

var player_hp_label: Label
var enemy_hp_label: Label
var player_energy_label: Label
var hand_container: Container
var battle_log: TextEdit
var end_turn_button: Button

# 新增UI元素
var enemy_intent_label: Label
var deck_status_label: Label

var battle_controller: BattleController
var card_ui_scene = preload("res://scenes/card.tscn")
var active_card_uis: Array[CardUI] = []

signal card_play_requested(card_data)
signal end_turn_requested

func _ready():
	print("BattleUI _ready called")
	setup_ui_references()
	create_additional_ui()
	create_battle_controller()
	connect_signals()
	
	# 🔧 启用输入处理用于调试
	set_process_input(true)
	
	print("BattleUI setup complete")

func setup_ui_references():
	print("Setting up UI references...")
	
	if player_hp_label_path:
		player_hp_label = get_node(player_hp_label_path)
		print("Player HP label found: ", player_hp_label != null)
	
	if enemy_hp_label_path:
		enemy_hp_label = get_node(enemy_hp_label_path)
		print("Enemy HP label found: ", enemy_hp_label != null)
	
	if player_energy_label_path:
		player_energy_label = get_node(player_energy_label_path)
		print("Player energy label found: ", player_energy_label != null)
	
	if hand_container_path:
		hand_container = get_node(hand_container_path)
		print("Hand container found: ", hand_container != null)
		
		# 🔧 关键修复：确保手牌容器不阻挡事件
		if hand_container:
			hand_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			print("Hand container mouse_filter set to IGNORE")
			
			# 确保容器可见
			hand_container.visible = true
			print("Hand container visible: ", hand_container.visible)
	
	if battle_log_path:
		battle_log = get_node(battle_log_path)
		if battle_log:
			battle_log.editable = false
			battle_log.mouse_filter = Control.MOUSE_FILTER_PASS
			print("Battle log found and configured")
	
	if end_turn_button_path:
		end_turn_button = get_node(end_turn_button_path)
		if end_turn_button:
			end_turn_button.pressed.connect(_on_end_turn_pressed)
			end_turn_button.text = "结束回合"
			print("End turn button found and connected")

func create_additional_ui():
	print("Creating additional UI elements...")
	
	# 创建敌人意图显示标签
	if enemy_hp_label and enemy_hp_label.get_parent():
		enemy_intent_label = Label.new()
		enemy_intent_label.text = "意图: 未知"
		enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		enemy_hp_label.get_parent().add_child(enemy_intent_label)
		enemy_hp_label.get_parent().move_child(enemy_intent_label, enemy_hp_label.get_index() + 1)
		print("Enemy intent label created")
	
	# 创建牌组状态显示
	if battle_log and battle_log.get_parent():
		deck_status_label = Label.new()
		deck_status_label.text = "牌库: 0 | 手牌: 0 | 弃牌: 0"
		deck_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		battle_log.get_parent().add_child(deck_status_label)
		battle_log.get_parent().move_child(deck_status_label, battle_log.get_index())
		print("Deck status label created")

func create_battle_controller():
	print("Creating battle controller...")
	battle_controller = BattleController.new()
	add_child(battle_controller)
	print("Battle controller created and added")

func connect_signals():
	print("Connecting signals...")
	
	if battle_controller:
		battle_controller.ui_update_requested.connect(_on_ui_update_requested)
		battle_controller.log_message.connect(_on_log_message)
		battle_controller.battle_won.connect(_on_battle_won)
		battle_controller.battle_lost.connect(_on_battle_lost)
		print("Battle controller signals connected")
	
	card_play_requested.connect(battle_controller.play_card)
	end_turn_requested.connect(battle_controller.end_player_turn)
	print("UI signals connected to controller")

func _on_ui_update_requested(data: Dictionary):
	print("=== UI UPDATE REQUESTED ===")
	print("Hand cards count: ", data.get("hand_cards", []).size())
	print("Current active card UIs: ", active_card_uis.size())
	
	update_ui_display(data)
	update_hand_display(data.get("hand_cards", []))

func update_ui_display(data: Dictionary):
	# 更新玩家信息
	if player_hp_label:
		var hp_text = "生命: %d/%d" % [data.get("player_hp", 0), data.get("player_max_hp", 0)]
		if data.has("player_block") and data.player_block > 0:
			hp_text += " (护甲: %d)" % data.player_block
		player_hp_label.text = hp_text
	
	# 更新敌人信息
	if enemy_hp_label:
		var enemy_hp_text = "%s: %d/%d" % [data.get("enemy_name", "敌人"), data.get("enemy_hp", 0), data.get("enemy_max_hp", 0)]
		if data.has("enemy_block") and data.enemy_block > 0:
			enemy_hp_text += " (护甲: %d)" % data.enemy_block
		enemy_hp_label.text = enemy_hp_text
	
	# 更新敌人意图
	if enemy_intent_label and data.has("enemy_intent"):
		var intent = data.enemy_intent
		var intent_text = "意图: " + intent.get("name", "未知")
		if intent.get("type") == "attack":
			intent_text += " (" + str(intent.get("damage", 0)) + " 伤害)"
		elif intent.get("type") == "defend":
			intent_text += " (" + str(intent.get("block", 0)) + " 护甲)"
		enemy_intent_label.text = intent_text
	
	# 更新玩家能量
	if player_energy_label:
		var energy_text = "能量: %d/%d" % [data.get("player_energy", 0), data.get("player_max_energy", 0)]
		player_energy_label.text = energy_text
		print("Updated energy display: ", energy_text)
	
	# 更新牌组状态
	if deck_status_label and data.has("deck_status"):
		var status = data.deck_status
		deck_status_label.text = "牌库: %d | 手牌: %d | 弃牌: %d" % [status.get("deck_size", 0), status.get("hand_size", 0), status.get("discard_size", 0)]
	
	# 更新结束回合按钮
	if end_turn_button:
		var is_player_turn = data.get("is_player_turn", false)
		end_turn_button.disabled = not is_player_turn
		if is_player_turn:
			end_turn_button.text = "结束回合"
		else:
			end_turn_button.text = "敌人回合"
	
	# 🔧 更新手牌的可用性（基于当前能量）
	update_cards_affordability(data.get("player_energy", 0))

func update_hand_display(hand_cards: Array):
	print("=== UPDATING HAND DISPLAY ===")
	print("New hand cards: ", hand_cards.size())
	print("Container children before clear: ", hand_container.get_child_count() if hand_container else 0)
	
	# 🔧 智能更新：只在手牌真正改变时才重建
	if should_rebuild_hand(hand_cards):
		print("Hand changed, rebuilding...")
		clear_hand_display_completely()
		
		print("Container children after clear: ", hand_container.get_child_count() if hand_container else 0)
		
		# 创建新的卡牌UI
		for i in range(hand_cards.size()):
			var card_data = hand_cards[i]
			print("Creating card ", i, ": ", card_data.get("name", "Unknown"))
			create_card_ui(card_data)
		
		print("Container children after creation: ", hand_container.get_child_count() if hand_container else 0)
		print("Active card UIs: ", active_card_uis.size())
	else:
		print("Hand unchanged, skipping rebuild")

func should_rebuild_hand(new_hand_cards: Array) -> bool:
	# 如果数量不同，需要重建
	if active_card_uis.size() != new_hand_cards.size():
		return true
	
	# 检查每张卡是否相同
	for i in range(new_hand_cards.size()):
		if i >= active_card_uis.size():
			return true
		
		var new_card = new_hand_cards[i]
		var existing_card = active_card_uis[i].card_data
		
		# 比较卡牌ID（唯一标识）
		if new_card.get("id", "") != existing_card.get("id", ""):
			return true
	
	return false

func clear_hand_display_completely():
	print("=== CLEARING HAND DISPLAY COMPLETELY ===")
	
	if not hand_container:
		print("ERROR: hand_container is null!")
		return
	
	print("Clearing ", active_card_uis.size(), " active card UIs")
	print("Container has ", hand_container.get_child_count(), " children")
	
	# 方法1：清理我们跟踪的卡牌UI
	for card_ui in active_card_uis:
		if is_instance_valid(card_ui):
			print("Removing tracked card UI: ", card_ui.card_data.get("name", "Unknown"))
			if card_ui.get_parent():
				card_ui.get_parent().remove_child(card_ui)
			card_ui.queue_free()
	active_card_uis.clear()
	
	# 方法2：清理容器中的所有子节点（确保没有遗漏）
	var children_to_remove = []
	for child in hand_container.get_children():
		if child is CardUI:
			children_to_remove.append(child)
	
	for child in children_to_remove:
		print("Removing container child: ", child)
		hand_container.remove_child(child)
		child.queue_free()
	
	# 方法3：强制处理队列，确保立即清理
	await get_tree().process_frame
	
	print("Final container children count: ", hand_container.get_child_count())

func create_card_ui(card_data: Dictionary):
	if not hand_container:
		print("ERROR: hand_container is null!")
		return
	
	if not card_ui_scene:
		print("ERROR: card_ui_scene is null!")
		return
	
	var card_ui = card_ui_scene.instantiate() as CardUI
	if not card_ui:
		print("ERROR: Failed to instantiate card UI!")
		return
	
	print("Creating card UI for: ", card_data.get("name", "Unknown"))
	
	# 🔧 关键修复：先设置卡牌数据
	card_ui.setup_card(card_data)
	
	# 然后添加到容器
	hand_container.add_child(card_ui)
	
	# 🔧 确保卡牌可交互
	card_ui.set_interactable(true)
	
	# 🔧 延迟连接信号，确保节点完全准备好
	call_deferred("connect_card_signal", card_ui)
	
	# 为手牌容器添加间距
	if hand_container is HBoxContainer:
		hand_container.add_theme_constant_override("separation", 10)
	
	active_card_uis.append(card_ui)
	
	print("Card UI created successfully")
	print("  - Position: ", card_ui.position)
	print("  - Size: ", card_ui.size)
	print("  - Mouse filter: ", card_ui.mouse_filter)
	print("  - Visible: ", card_ui.visible)

func connect_card_signal(card_ui: CardUI):
	if not is_instance_valid(card_ui):
		print("WARNING: Card UI is not valid for signal connection")
		return
	
	if not card_ui.card_played.is_connected(_on_card_played):
		card_ui.card_played.connect(_on_card_played)
		print("✅ Connected signal for card: ", card_ui.card_data.get("name", "Unknown"))
	else:
		print("⚠️ Signal already connected for card: ", card_ui.card_data.get("name", "Unknown"))

func _on_card_played(card_data: Dictionary, card_ui: CardUI):
	print("🎯 Card played signal received: ", card_data.get("name", "Unknown"))
	
	# 🔧 首先检查card_ui是否仍然有效
	if not is_instance_valid(card_ui):
		print("❌ Card UI is no longer valid, skipping")
		return
	
	# 🔧 立即禁用卡牌防止重复点击
	card_ui.set_interactable(false)
	print("Card disabled: ", card_data.get("name", "Unknown"))
	
	# 🔧 从数组中安全地查找和移除卡牌
	var card_index = -1
	for i in range(active_card_uis.size()):
		if active_card_uis[i] == card_ui:
			card_index = i
			break
	
	if card_index >= 0:
		active_card_uis.remove_at(card_index)
		print("Removed card from active_card_uis array at index: ", card_index)
	else:
		print("⚠️ Card UI not found in active_card_uis array")
	
	# 发送给控制器
	print("📡 Emitting card_play_requested...")
	card_play_requested.emit(card_data)
	
	# 🔧 延迟一帧检查卡牌是否被成功打出
	await get_tree().process_frame
	
	# 再次检查card_ui是否仍然有效
	if not is_instance_valid(card_ui):
		print("Card UI became invalid during processing")
		return
	
	# 🔧 检查卡牌是否真的被打出（通过检查是否还在手牌中）
	var card_still_in_hand = false
	if battle_controller and battle_controller.deck_manager:
		var current_hand = battle_controller.deck_manager.get_hand_cards()
		for hand_card in current_hand:
			if hand_card.get("id", "") == card_data.get("id", ""):
				card_still_in_hand = true
				break
	
	if card_still_in_hand:
		# 卡牌没有被打出（费用不足等），恢复卡牌状态
		print("Card not played, restoring state")
		card_ui.set_interactable(true)
		# 重新添加到数组中
		if card_ui not in active_card_uis:
			active_card_uis.append(card_ui)
			print("Re-added card to active_card_uis array")
		return
	
	# 卡牌确实被打出，安全地移除UI
	print("Card successfully played, removing UI")
	safe_remove_card_ui(card_ui)

# 🔧 新的安全移除方法
func safe_remove_card_ui(card_ui: CardUI):
	if not is_instance_valid(card_ui):
		print("Card UI is not valid, skipping removal")
		return
	
	# 确保从父节点移除
	var card_parent = card_ui.get_parent()
	if card_parent and is_instance_valid(card_parent):
		card_parent.remove_child(card_ui)
		print("Removed card from parent: ", card_parent.name)
	else:
		print("Card has no valid parent or parent is invalid")
	
	# 标记为删除
	card_ui.queue_free()
	print("Card UI queued for deletion")

# 保留原来的方法以防其他地方调用
func remove_card_ui(card_ui):
	# 🔧 添加类型检查和空值检查
	if card_ui == null:
		print("remove_card_ui called with null argument")
		return
	
	if not is_instance_valid(card_ui):
		print("remove_card_ui called with invalid object")
		return
	
	if not card_ui is CardUI:
		print("remove_card_ui called with wrong type: ", typeof(card_ui))
		return
	
	safe_remove_card_ui(card_ui)

func update_cards_affordability(current_energy: int):
	print("Updating cards affordability with energy: ", current_energy)
	
	for card_ui in active_card_uis:
		if not is_instance_valid(card_ui):
			continue
		
		var card_cost = card_ui.card_data.get("cost", 0)
		var can_afford = current_energy >= card_cost
		
		# 🔧 视觉反馈：不能负担的卡牌变灰
		if can_afford:
			card_ui.modulate = Color.WHITE
			card_ui.set_interactable(true)
		else:
			card_ui.modulate = Color(0.5, 0.5, 0.5, 1.0)  # 变灰
			card_ui.set_interactable(false)
		
		print("Card ", card_ui.card_data.get("name", "Unknown"), " cost: ", card_cost, " affordable: ", can_afford)

func _on_end_turn_pressed():
	print("End turn button pressed")
	end_turn_requested.emit()

func _on_log_message(message: String):
	if battle_log:
		battle_log.text += message + "\n"
		# 延迟滚动到底部
		call_deferred("scroll_log_to_bottom")

func scroll_log_to_bottom():
	if battle_log:
		battle_log.scroll_vertical = battle_log.get_line_count()

func _on_battle_won():
	show_result_dialog("胜利!", "恭喜你击败了敌人!")

func _on_battle_lost():
	show_result_dialog("失败!", "你在战斗中败北了...")

func show_result_dialog(title: String, message: String):
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func(): 
		dialog.queue_free()
		SceneManager.load_tower_scene()
	)

func debug_hand_ui():
	print("=== HAND DEBUG INFO ===")
	print("Hand container: ", hand_container)
	print("Hand container children: ", hand_container.get_child_count() if hand_container else 0)
	print("Active card UIs: ", active_card_uis.size())
	
	if hand_container:
		print("Hand container mouse_filter: ", hand_container.mouse_filter)
		print("Hand container visible: ", hand_container.visible)
		print("Hand container position: ", hand_container.position)
		print("Hand container size: ", hand_container.size)
		
		for i in range(hand_container.get_child_count()):
			var child = hand_container.get_child(i)
			if child is CardUI:
				print("  Card %d: %s" % [i, child.card_data.get("name", "Unknown")])
				print("    Position: ", child.position)
				print("    Size: ", child.size)
				print("    Mouse filter: ", child.mouse_filter)
				print("    Visible: ", child.visible)
				print("    Interactable: ", child.is_interactable if "is_interactable" in child else "Unknown")

func force_refresh_hand():
	print("🔄 Force refreshing hand display...")
	if battle_controller:
		battle_controller.emit_ui_update()

func test_first_card():
	print("🧪 Testing first card click...")
	if active_card_uis.size() > 0:
		var test_card = active_card_uis[0]
		print("Testing card: ", test_card.card_data.get("name", "Unknown"))
		test_card.play_card()
	else:
		print("No cards available for testing")

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_F1:
			print("🔍 F1 - Debug hand UI")
			debug_hand_ui()
		KEY_F2:
			print("🔄 F2 - Force refresh hand")
			force_refresh_hand()
		KEY_F3:
			print("🧪 F3 - Test first card")
			test_first_card()
		KEY_F4:
			print("🎮 F4 - Create test button")
			create_test_button()

func create_test_button():
	# 检查是否已经有测试按钮
	var existing_button = get_node_or_null("TestButton")
	if existing_button:
		print("Test button already exists")
		return
	
	var test_button = Button.new()
	test_button.name = "TestButton"
	test_button.text = "测试出牌"
	test_button.position = Vector2(500, 500)
	test_button.size = Vector2(120, 50)
	test_button.z_index = 100
	add_child(test_button)
	
	test_button.pressed.connect(func():
		print("🧪 Test button pressed")
		if active_card_uis.size() > 0:
			var first_card = active_card_uis[0]
			print("Playing first card: ", first_card.card_data.get("name", "Unknown"))
			_on_card_played(first_card.card_data, first_card)
		else:
			print("No cards available")
	)
	
	print("✅ Test button created at position: ", test_button.position)
