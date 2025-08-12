extends Control

# 商店UI控制器
class_name ShopUI

var gold_label: Label
var shop_container: GridContainer
var back_button: Button

var card_ui_scene = preload("res://scenes/card.tscn")
var shop_cards: Array[Dictionary] = []
var player_gold: int = 100  # 初始金币

signal shop_closed

func _ready():
	setup_ui()
	connect_signals()
	generate_shop_inventory()
	update_display()

func setup_ui():
	# 创建背景
	var background = ColorRect.new()
	background.color = Color(0.3, 0.2, 0.1, 1)
	background.anchors_preset = Control.PRESET_FULL_RECT
	add_child(background)
	
	# 创建主容器
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	add_child(vbox)
	
	# 标题和金币显示
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title = Label.new()
	title.text = "商店"
	title.add_theme_font_size_override("font_size", 32)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 24)
	header.add_child(gold_label)
	
	# 商品容器
	shop_container = GridContainer.new()
	shop_container.columns = 3
	shop_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(shop_container)
	
	# 返回按钮
	back_button = Button.new()
	back_button.text = "离开商店"
	back_button.custom_minimum_size = Vector2(150, 50)
	vbox.add_child(back_button)

func connect_signals():
	back_button.pressed.connect(_on_back_pressed)

func generate_shop_inventory():
	shop_cards = CardRewards.generate_shop_cards(GameData.current_floor)
	
	# 添加一些遗物到商店
	shop_cards.append({
		"name": "力量护符",
		"description": "所有攻击牌伤害+1",
		"type": "relic",
		"price": 150,
		"rarity": "uncommon"
	})
	
	shop_cards.append({
		"name": "生命药水",
		"description": "立即恢复20点生命",
		"type": "potion",
		"price": 75,
		"rarity": "common"
	})

func update_display():
	gold_label.text = "金币: %d" % player_gold
	
	# 清除现有商品显示
	for child in shop_container.get_children():
		child.queue_free()
	
	# 创建商品UI
	for item_data in shop_cards:
		create_shop_item_ui(item_data)

func create_shop_item_ui(item_data: Dictionary):
	var item_container = VBoxContainer.new()
	item_container.custom_minimum_size = Vector2(200, 250)
	shop_container.add_child(item_container)
	
	if item_data.type == "relic" or item_data.type == "potion":
		create_special_item_ui(item_container, item_data)
	else:
		create_card_item_ui(item_container, item_data)

func create_card_item_ui(container: VBoxContainer, card_data: Dictionary):
	# 创建卡牌UI
	var card_ui = card_ui_scene.instantiate() as CardUI
	card_ui.custom_minimum_size = Vector2(120, 160)
	card_ui.set_interactable(false)
	container.add_child(card_ui)
	card_ui.setup_card(card_data)
	
	# 价格标签
	var price_label = Label.new()
	price_label.text = "价格: %d 金币" % card_data.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(price_label)
	
	# 购买按钮
	var buy_button = Button.new()
	buy_button.text = "购买"
	buy_button.disabled = player_gold < card_data.price
	container.add_child(buy_button)
	
	buy_button.pressed.connect(func(): buy_item(card_data, buy_button, container))

func create_special_item_ui(container: VBoxContainer, item_data: Dictionary):
	# 物品图标/背景
	var item_bg = ColorRect.new()
	item_bg.custom_minimum_size = Vector2(120, 160)
	item_bg.color = CardRewards.get_rarity_color(item_data.rarity)
	container.add_child(item_bg)
	
	# 物品信息
	var info_vbox = VBoxContainer.new()
	item_bg.add_child(info_vbox)
	info_vbox.anchors_preset = Control.PRESET_FULL_RECT
	info_vbox.offset_left = 5
	info_vbox.offset_top = 5
	info_vbox.offset_right = -5
	info_vbox.offset_bottom = -5
	
	var name_label = Label.new()
	name_label.text = item_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(desc_label)
	
	# 价格标签
	var price_label = Label.new()
	price_label.text = "价格: %d 金币" % item_data.price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(price_label)
	
	# 购买按钮
	var buy_button = Button.new()
	buy_button.text = "购买"
	buy_button.disabled = player_gold < item_data.price
	container.add_child(buy_button)
	
	buy_button.pressed.connect(func(): buy_item(item_data, buy_button, container))

func buy_item(item_data: Dictionary, button: Button, container: Control):
	if player_gold < item_data.price:
		show_message("金币不足!")
		return
	
	# 扣除金币
	player_gold -= item_data.price
	
	# 根据物品类型处理
	match item_data.type:
		"attack", "skill", "power":
			GameData.add_card_to_deck(item_data)
			show_message("购买了卡牌: " + item_data.name)
		"relic":
			GameData.add_relic(item_data)
			show_message("购买了遗物: " + item_data.name)
		"potion":
			if item_data.name == "生命药水":
				var heal_amount = min(20, GameData.player_max_hp - GameData.player_hp)
				GameData.player_hp += heal_amount
				show_message("使用了生命药水，恢复了 %d 点生命" % heal_amount)
	
	# 移除已购买的物品
	shop_cards.erase(item_data)
	container.queue_free()
	
	# 更新显示
	update_display()

func _on_back_pressed():
	shop_closed.emit()
	SceneManager.load_tower_scene()

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# 显示商店的静态方法
static func show_shop(parent: Node) -> ShopUI:
	var shop_ui = ShopUI.new()
	parent.add_child(shop_ui)
	return shop_ui