extends Control

# 卡牌奖励UI控制器
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
	setup_ui_references()
	connect_signals()

func setup_ui_references():
	title_label = $CenterContainer/VBoxContainer/TitleLabel
	rewards_container = $CenterContainer/VBoxContainer/RewardsContainer
	skip_button = $CenterContainer/VBoxContainer/ButtonContainer/SkipButton
	confirm_button = $CenterContainer/VBoxContainer/ButtonContainer/ConfirmButton

func connect_signals():
	skip_button.pressed.connect(_on_skip_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

func setup_rewards(cards: Array[Dictionary]):
	reward_cards = cards
	clear_rewards_display()
	
	for card_data in reward_cards:
		create_reward_card_ui(card_data)
	
	# 重置选择状态
	selected_card = {}
	selected_card_ui = null
	confirm_button.disabled = true

func clear_rewards_display():
	for child in rewards_container.get_children():
		child.queue_free()

func create_reward_card_ui(card_data: Dictionary):
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
	
	# 连接点击事件
	card_ui.gui_input.connect(_on_reward_card_clicked.bind(card_data, card_ui))
	
	# 禁用拖拽功能
	card_ui.set_interactable(false)
	card_ui.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_reward_card_clicked(card_data: Dictionary, card_ui: CardUI, event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_card(card_data, card_ui)

func select_card(card_data: Dictionary, card_ui: CardUI):
	# 取消之前的选择
	if selected_card_ui and is_instance_valid(selected_card_ui):
		selected_card_ui.scale = Vector2.ONE
		selected_card_ui.modulate = Color.WHITE
	
	# 选择新卡牌
	selected_card = card_data
	selected_card_ui = card_ui
	
	# 高亮选中的卡牌
	card_ui.scale = Vector2(1.1, 1.1)
	card_ui.modulate = Color.YELLOW
	
	# 启用确认按钮
	confirm_button.disabled = false
	
	print("Selected reward card: ", card_data.name)

func _on_skip_pressed():
	print("Reward skipped")
	reward_skipped.emit()
	close_reward_screen()

func _on_confirm_pressed():
	if not selected_card.is_empty():
		print("Reward confirmed: ", selected_card.name)
		reward_confirmed.emit(selected_card)
		close_reward_screen()

func close_reward_screen():
	queue_free()

# 显示卡牌奖励的静态方法
static func show_card_rewards(parent: Node, cards: Array[Dictionary]) -> CardRewardUI:
	var reward_scene = preload("res://scenes/card_reward.tscn")
	var reward_ui = reward_scene.instantiate() as CardRewardUI
	parent.add_child(reward_ui)
	reward_ui.setup_rewards(cards)
	return reward_ui
