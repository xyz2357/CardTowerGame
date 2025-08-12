extends Control

# 休息点UI控制器
class_name RestSiteUI

var heal_button: Button
var upgrade_button: Button
var remove_button: Button
var back_button: Button
var status_label: Label

signal rest_action_completed

func _ready():
	setup_ui()
	connect_signals()
	update_display()

func setup_ui():
	# 创建背景
	var background = ColorRect.new()
	background.color = Color(0.2, 0.3, 0.2, 1)
	background.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background)
	
	# 创建主容器
	var center_container = CenterContainer.new()
	center_container.anchors_preset = Control.PRESET_FULL_RECT
	add_child(center_container)
	
	var vbox = VBoxContainer.new()
	center_container.add_child(vbox)
	
	# 标题
	var title = Label.new()
	title.text = "篝火"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	# 状态显示
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	# 间距
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# 按钮容器
	var button_container = VBoxContainer.new()
	vbox.add_child(button_container)
	
	# 治疗按钮
	heal_button = Button.new()
	heal_button.text = "恢复生命 (30%)"
	heal_button.custom_minimum_size = Vector2(200, 50)
	button_container.add_child(heal_button)
	
	# 升级按钮
	upgrade_button = Button.new()
	upgrade_button.text = "升级卡牌"
	upgrade_button.custom_minimum_size = Vector2(200, 50)
	button_container.add_child(upgrade_button)
	
	# 移除按钮（高级选项）
	remove_button = Button.new()
	remove_button.text = "移除卡牌"
	remove_button.custom_minimum_size = Vector2(200, 50)
	remove_button.modulate = Color.GRAY
	button_container.add_child(remove_button)
	
	# 间距
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# 返回按钮
	back_button = Button.new()
	back_button.text = "离开"
	back_button.custom_minimum_size = Vector2(100, 40)
	vbox.add_child(back_button)

func connect_signals():
	heal_button.pressed.connect(_on_heal_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	back_button.pressed.connect(_on_back_pressed)

func update_display():
	var heal_amount = int(GameData.player_max_hp * 0.3)
	var current_heal = min(heal_amount, GameData.player_max_hp - GameData.player_hp)
	
	status_label.text = "生命: %d/%d" % [GameData.player_hp, GameData.player_max_hp]
	
	if current_heal <= 0:
		heal_button.text = "恢复生命 (已满)"
		heal_button.disabled = true
	else:
		heal_button.text = "恢复生命 (+%d)" % current_heal
		heal_button.disabled = false
	
	# 检查是否有可升级的卡牌
	var upgradeable_cards = get_upgradeable_cards()
	upgrade_button.disabled = upgradeable_cards.is_empty()
	
	# 移除卡牌需要特定条件
	remove_button.disabled = GameData.player_deck.size() <= 10

func get_upgradeable_cards() -> Array:
	var upgradeable = []
	for card in GameData.player_deck:
		if not card.name.ends_with("+"):
			upgradeable.append(card)
	return upgradeable

func _on_heal_pressed():
	var heal_amount = int(GameData.player_max_hp * 0.3)
	var actual_heal = min(heal_amount, GameData.player_max_hp - GameData.player_hp)
	
	if actual_heal > 0:
		GameData.player_hp += actual_heal
		show_message("恢复了 %d 点生命值" % actual_heal)
		update_display()
		
		# 禁用治疗按钮（一次休息只能选择一个选项）
		disable_all_buttons()

func _on_upgrade_pressed():
	var upgradeable_cards = get_upgradeable_cards()
	if upgradeable_cards.is_empty():
		show_message("没有可升级的卡牌")
		return
	
	show_card_selection_for_upgrade(upgradeable_cards)

func _on_remove_pressed():
	if GameData.player_deck.size() <= 10:
		show_message("卡牌数量太少，无法移除")
		return
	
	show_card_selection_for_removal()

func _on_back_pressed():
	rest_action_completed.emit()
	SceneManager.load_tower_scene()

func show_card_selection_for_upgrade(cards: Array):
	# 简化版本：随机选择一张卡牌升级
	var random_card = cards[randi() % cards.size()]
	var success = GameData.upgrade_card_in_deck(random_card.name)
	
	if success:
		show_message("升级了卡牌: " + random_card.name + "+")
		disable_all_buttons()
	else:
		show_message("升级失败")

func show_card_selection_for_removal():
	# 简化版本：显示确认对话框
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "确定要移除一张基础攻击卡吗？"
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func():
		var success = GameData.remove_card_from_deck("攻击")
		if success:
			show_message("移除了一张攻击卡")
			disable_all_buttons()
		else:
			show_message("移除失败")
		dialog.queue_free()
	)
	
	dialog.get_cancel_button().pressed.connect(func():
		dialog.queue_free()
	)

func disable_all_buttons():
	heal_button.disabled = true
	upgrade_button.disabled = true
	remove_button.disabled = true

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# 显示休息点的静态方法
static func show_rest_site(parent: Node) -> RestSiteUI:
	var rest_ui = RestSiteUI.new()
	parent.add_child(rest_ui)
	return rest_ui