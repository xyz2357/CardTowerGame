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

var battle_controller: BattleController
var card_ui_scene = preload("res://scenes/card.tscn")
var active_card_uis: Array[CardUI] = []

signal card_play_requested(card_data)
signal end_turn_requested

func _ready():
	# 获取UI节点引用
	setup_ui_references()
	
	# 创建战斗控制器
	battle_controller = BattleController.new()
	add_child(battle_controller)
	
	# 连接信号
	connect_signals()

func setup_ui_references():
	if player_hp_label_path:
		player_hp_label = get_node(player_hp_label_path)
	if enemy_hp_label_path:
		enemy_hp_label = get_node(enemy_hp_label_path)
	if player_energy_label_path:
		player_energy_label = get_node(player_energy_label_path)
	if hand_container_path:
		hand_container = get_node(hand_container_path)
	if battle_log_path:
		battle_log = get_node(battle_log_path)
	if end_turn_button_path:
		end_turn_button = get_node(end_turn_button_path)
		end_turn_button.pressed.connect(_on_end_turn_pressed)

func connect_signals():
	# 连接战斗控制器信号
	battle_controller.ui_update_requested.connect(_on_ui_update_requested)
	battle_controller.log_message.connect(_on_log_message)
	battle_controller.battle_won.connect(_on_battle_won)
	battle_controller.battle_lost.connect(_on_battle_lost)
	
	# 连接UI信号到控制器
	card_play_requested.connect(battle_controller.play_card)
	end_turn_requested.connect(battle_controller.end_player_turn)

func _on_ui_update_requested(data: Dictionary):
	update_ui_display(data)
	update_hand_display(data.get("hand_cards", []))

func update_ui_display(data: Dictionary):
	if player_hp_label:
		player_hp_label.text = "生命: %d/%d" % [data.player_hp, data.player_max_hp]
		if data.has("player_block") and data.player_block > 0:
			player_hp_label.text += " (护甲: %d)" % data.player_block
	
	if enemy_hp_label:
		enemy_hp_label.text = "敌人生命: %d/%d" % [data.enemy_hp, data.enemy_max_hp]
	
	if player_energy_label:
		player_energy_label.text = "能量: %d/%d" % [data.player_energy, data.player_max_energy]
	
	if end_turn_button:
		end_turn_button.disabled = not data.get("is_player_turn", false)

func update_hand_display(hand_cards: Array):
	# 清除旧的卡牌UI
	clear_hand_display()
	
	# 创建新的卡牌UI
	for card_data in hand_cards:
		create_card_ui(card_data)

func clear_hand_display():
	for card_ui in active_card_uis:
		if is_instance_valid(card_ui):
			card_ui.queue_free()
	active_card_uis.clear()

func create_card_ui(card_data: Dictionary):
	if not hand_container or not card_ui_scene:
		return
	
	var card_ui = card_ui_scene.instantiate() as CardUI
	hand_container.add_child(card_ui)
	card_ui.setup_card(card_data)
	card_ui.card_played.connect(_on_card_played)
	
	active_card_uis.append(card_ui)

func _on_card_played(card_data: Dictionary, card_ui: CardUI):
	card_play_requested.emit(card_data)
	# 移除已打出的卡牌UI
	if card_ui in active_card_uis:
		active_card_uis.erase(card_ui)
	card_ui.queue_free()

func _on_end_turn_pressed():
	end_turn_requested.emit()

func _on_log_message(message: String):
	if battle_log:
		battle_log.text += message + "\n"
		# 自动滚动到底部
		battle_log.scroll_vertical = battle_log.get_line_count()

func _on_battle_won():
	show_result_dialog("胜利!", "恭喜你赢得了战斗!")

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
		# 返回地图场景
		SceneManager.load_tower_scene()
	)
