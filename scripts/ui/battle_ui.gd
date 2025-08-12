extends Control

# 战斗UI控制器 - 只负责UI展示和用户交互
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
	# 获取UI节点引用
	setup_ui_references()
	
	# 创建额外的UI元素
	create_additional_ui()
	
	# 创建战斗控制器
	battle_controller = BattleController.new()
	add_child(battle_controller)
	
	# 连接信号
	connect_signals()
	
	print("BattleUI setup complete")

func setup_ui_references():
	print("Setting up UI references...")
	
	if player_hp_label_path:
		player_hp_label = get_node(player_hp_label_path)
		print("Player HP label found: ", player_hp_label)
	
	if enemy_hp_label_path:
		enemy_hp_label = get_node(enemy_hp_label_path)
		print("Enemy HP label found: ", enemy_hp_label)
	
	if player_energy_label_path:
		player_energy_label = get_node(player_energy_label_path)
		print("Player energy label found: ", player_energy_label)
	
	if hand_container_path:
		hand_container = get_node(hand_container_path)
		print("Hand container found: ", hand_container)
	
	if battle_log_path:
		battle_log = get_node(battle_log_path)
		print("Battle log found: ", battle_log)
		if battle_log:
			battle_log.editable = false
	
	if end_turn_button_path:
		end_turn_button = get_node(end_turn_button_path)
		if end_turn_button:
			end_turn_button.pressed.connect(_on_end_turn_pressed)
			end_turn_button.text = "结束回合"
		print("End turn button found: ", end_turn_button)

func create_additional_ui():
	# 创建敌人意图显示标签
	if enemy_hp_label and enemy_hp_label.get_parent():
		enemy_intent_label = Label.new()
		enemy_intent_label.text = "意图: 未知"
		enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		enemy_hp_label.get_parent().add_child(enemy_intent_label)
		enemy_hp_label.get_parent().move_child(enemy_intent_label, enemy_hp_label.get_index() + 1)
	
	# 创建牌组状态显示
	if battle_log:
		deck_status_label = Label.new()
		deck_status_label.text = "牌库: 0 | 手牌: 0 | 弃牌: 0"
		deck_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		battle_log.get_parent().add_child(deck_status_label)
		battle_log.get_parent().move_child(deck_status_label, battle_log.get_index())

func connect_signals():
	print("Connecting signals...")
	# 连接战斗控制器信号
	battle_controller.ui_update_requested.connect(_on_ui_update_requested)
	battle_controller.log_message.connect(_on_log_message)
	battle_controller.battle_won.connect(_on_battle_won)
	battle_controller.battle_lost.connect(_on_battle_lost)
	
	# 连接UI信号到控制器
	card_play_requested.connect(battle_controller.play_card)
	end_turn_requested.connect(battle_controller.end_player_turn)
	
	print("All signals connected")

func _on_ui_update_requested(data: Dictionary):
	print("UI update requested with data keys: ", data.keys())
	print("Hand cards count: ", data.get("hand_cards", []).size())
	
	update_ui_display(data)
	update_hand_display(data.get("hand_cards", []))

func update_ui_display(data: Dictionary):
	# 更新玩家信息
	if player_hp_label:
		var hp_text = "生命: %d/%d" % [data.player_hp, data.player_max_hp]
		if data.has("player_block") and data.player_block > 0:
			hp_text += " (护甲: %d)" % data.player_block
		player_hp_label.text = hp_text
	
	# 更新敌人信息
	if enemy_hp_label:
		var enemy_hp_text = "%s: %d/%d" % [data.get("enemy_name", "敌人"), data.enemy_hp, data.enemy_max_hp]
		if data.has("enemy_block") and data.enemy_block > 0:
			enemy_hp_text += " (护甲: %d)" % data.enemy_block
		enemy_hp_label.text = enemy_hp_text
	
	# 更新敌人意图
	if enemy_intent_label and data.has("enemy_intent"):
		var intent = data.enemy_intent
		var intent_text = "意图: " + intent.name
		if intent.type == "attack":
			intent_text += " (" + str(intent.damage) + " 伤害)"
		elif intent.type == "defend":
			intent_text += " (" + str(intent.block) + " 护甲)"
		enemy_intent_label.text = intent_text
	
	# 更新玩家能量
	if player_energy_label:
		player_energy_label.text = "能量: %d/%d" % [data.player_energy, data.player_max_energy]
	
	# 更新牌组状态
	if deck_status_label and data.has("deck_status"):
		var status = data.deck_status
		deck_status_label.text = "牌库: %d | 手牌: %d | 弃牌: %d" % [status.deck_size, status.hand_size, status.discard_size]
	
	# 更新结束回合按钮
	if end_turn_button:
		end_turn_button.disabled = not data.get("is_player_turn", false)
		if data.get("is_player_turn", false):
			end_turn_button.modulate = Color.WHITE
		else:
			end_turn_button.modulate = Color.GRAY

func update_hand_display(hand_cards: Array):
	print("Updating hand display with ", hand_cards.size(), " cards")
	
	# 清除旧的卡牌UI
	clear_hand_display()
	
	# 创建新的卡牌UI
	for i in range(hand_cards.size()):
		var card_data = hand_cards[i]
		print("Creating card UI for: ", card_data)
		create_card_ui(card_data)
	
	print("Hand display updated, active card UIs: ", active_card_uis.size())

func clear_hand_display():
	print("Clearing hand display, removing ", active_card_uis.size(), " cards")
	for card_ui in active_card_uis:
		if is_instance_valid(card_ui):
			card_ui.queue_free()
	active_card_uis.clear()

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
	
	hand_container.add_child(card_ui)
	card_ui.setup_card(card_data)
	card_ui.card_played.connect(_on_card_played)
	
	# 为手牌容器添加间距
	if hand_container is HBoxContainer:
		hand_container.add_theme_constant_override("separation", 10)
	
	active_card_uis.append(card_ui)
	print("Card UI created and added, total active: ", active_card_uis.size())

func _on_card_played(card_data: Dictionary, card_ui: CardUI):
	print("Card played: ", card_data)
	card_play_requested.emit(card_data)
	
	# 添加卡牌播放效果
	create_card_play_effect(card_ui.global_position)
	
	# 移除已打出的卡牌UI
	if card_ui in active_card_uis:
		active_card_uis.erase(card_ui)
	card_ui.queue_free()

func create_card_play_effect(position: Vector2):
	# 简单的卡牌播放效果
	var effect_label = Label.new()
	effect_label.text = "PLAYED!"
	effect_label.modulate = Color.YELLOW
	effect_label.position = position
	add_child(effect_label)
	
	var tween = create_tween()
	tween.parallel().tween_property(effect_label, "position", position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(effect_label, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(effect_label.queue_free)

func _on_end_turn_pressed():
	print("End turn button pressed")
	end_turn_requested.emit()
	
	# 按钮点击效果
	if end_turn_button:
		var original_scale = end_turn_button.scale
		var tween = create_tween()
		tween.tween_property(end_turn_button, "scale", original_scale * 0.9, 0.1)
		tween.tween_property(end_turn_button, "scale", original_scale, 0.1)

func _on_log_message(message: String):
	if battle_log:
		battle_log.text += message + "\n"
		# 自动滚动到底部
		battle_log.call_deferred("set", "scroll_vertical", battle_log.get_line_count())
		print("Log message added: ", message)

func _on_battle_won():
	show_result_dialog("胜利!", "恭喜你击败了敌人!\n\n点击确定返回地图。")

func _on_battle_lost():
	show_result_dialog("失败!", "你在战斗中败北了...\n\n点击确定返回地图。")

func show_result_dialog(title: String, message: String):
	# 禁用所有交互
	set_ui_interactable(false)
	
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.get_ok_button().text = "确定"
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func(): 
		dialog.queue_free()
		# 返回地图场景
		SceneManager.load_tower_scene()
	)

func set_ui_interactable(enabled: bool):
	# 设置所有卡牌的交互性
	for card_ui in active_card_uis:
		if is_instance_valid(card_ui):
			card_ui.set_interactable(enabled)
	
	# 设置结束回合按钮的交互性
	if end_turn_button:
		end_turn_button.disabled = not enabled

# 添加键盘快捷键支持
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				if end_turn_button and not end_turn_button.disabled:
					_on_end_turn_pressed()
			KEY_ESCAPE:
				# ESC键返回地图
				SceneManager.load_tower_scene()
