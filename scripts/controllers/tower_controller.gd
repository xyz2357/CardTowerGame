extends Node

# 爬塔控制器 - 纯逻辑，不依赖UI
class_name TowerController

signal ui_update_requested(data: Dictionary)
signal choices_update_requested(choices: Array)
signal message_requested(message: String)
signal battle_requested(enemy_data: Dictionary)

var tower_data: TowerData
var choice_generator: ChoiceGenerator

func _ready():
	initialize()

func initialize():
	tower_data = TowerData.new()
	choice_generator = ChoiceGenerator.new()
	
	# 从游戏数据恢复状态
	restore_from_game_data()
	
	# 使用延迟调用确保所有节点都已初始化
	call_deferred("delayed_initialization")

func delayed_initialization():
	# 生成当前楼层的选择
	generate_current_floor_choices()
	emit_ui_update()
	print("Tower controller initialized, floor: ", tower_data.current_floor)

func restore_from_game_data():
	tower_data.current_floor = GameData.current_floor
	tower_data.player_hp = GameData.player_hp
	tower_data.player_max_hp = GameData.player_max_hp
	print("Restored from game data - Floor: ", tower_data.current_floor)

func generate_current_floor_choices():
	var choices = choice_generator.generate_choices_for_floor(tower_data.current_floor)
	print("Generated ", choices.size(), " choices for floor ", tower_data.current_floor)
	for i in range(choices.size()):
		print("Choice ", i, ": ", choices[i])
	choices_update_requested.emit(choices)

func handle_choice_selected(choice_data: Dictionary):
	print("Choice selected: ", choice_data)
	match choice_data.type:
		ChoiceGenerator.ChoiceType.ENEMY, ChoiceGenerator.ChoiceType.ELITE, ChoiceGenerator.ChoiceType.BOSS:
			start_battle(choice_data)
		ChoiceGenerator.ChoiceType.REST:
			handle_rest_choice()
		ChoiceGenerator.ChoiceType.SHOP:
			handle_shop_choice()
		ChoiceGenerator.ChoiceType.TREASURE:
			handle_treasure_choice()

func start_battle(enemy_data: Dictionary):
	# 保存状态到全局数据
	save_to_game_data()
	
	# 设置敌人数据
	GameData.set_current_enemy_data(enemy_data)
	
	print("Starting battle with: ", enemy_data)
	battle_requested.emit(enemy_data)

func handle_rest_choice():
	print("Opening rest site...")
	save_to_game_data()
	
	# 显示休息点界面
	var rest_ui = RestSiteUI.show_rest_site(get_tree().current_scene)
	rest_ui.rest_action_completed.connect(_on_rest_completed)

func handle_shop_choice():
	print("Opening shop...")
	save_to_game_data()
	
	# 显示商店界面
	var shop_ui = ShopUI.show_shop(get_tree().current_scene)
	shop_ui.shop_closed.connect(_on_shop_closed)

func handle_treasure_choice():
	print("Opening treasure...")
	save_to_game_data()
	
	# 随机获得奖励
	var treasure_rewards = generate_treasure_rewards()
	show_treasure_rewards(treasure_rewards)

func generate_treasure_rewards() -> Dictionary:
	var reward_type = randi() % 3
	
	match reward_type:
		0:  # 金币
			var gold_amount = randi_range(40, 80)
			return {
				"type": "gold",
				"amount": gold_amount,
				"description": "获得了 %d 金币" % gold_amount
			}
		1:  # 稀有卡牌
			var rare_cards = CardRewards.get_cards_by_rarity()[CardRewards.Rarity.RARE]
			var random_card = rare_cards[randi() % rare_cards.size()]
			return {
				"type": "card",
				"card": random_card.duplicate(),
				"description": "获得了稀有卡牌: " + random_card.name
			}
		2:  # 遗物
			var relics = [
				{"name": "红宝石", "description": "最大生命值+15", "effect": "max_hp_bonus", "value": 15},
				{"name": "力量戒指", "description": "所有攻击伤害+1", "effect": "damage_bonus", "value": 1},
				{"name": "护甲符文", "description": "每回合开始获得2点护甲", "effect": "turn_armor", "value": 2}
			]
			var random_relic = relics[randi() % relics.size()]
			return {
				"type": "relic",
				"relic": random_relic.duplicate(),
				"description": "获得了遗物: " + random_relic.name
			}
		_:
			return {"type": "nothing", "description": "宝箱是空的..."}

func show_treasure_rewards(reward: Dictionary):
	var message = reward.description
	
	# 应用奖励效果
	match reward.type:
		"gold":
			# 金币系统可以后续添加
			pass
		"card":
			GameData.add_card_to_deck(reward.card)
		"relic":
			GameData.add_relic(reward.relic)
			apply_relic_effect(reward.relic)
	
	# 显示奖励消息
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "宝箱奖励"
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		dialog.queue_free()
		advance_floor()
	)

func apply_relic_effect(relic: Dictionary):
	match relic.effect:
		"max_hp_bonus":
			GameData.player_max_hp += relic.value
			GameData.player_hp += relic.value  # 同时增加当前生命
		"damage_bonus":
			# 这个效果在战斗中处理
			pass
		"turn_armor":
			# 这个效果在战斗中处理
			pass

func advance_floor():
	tower_data.current_floor += 1
	save_to_game_data()
	
	if tower_data.current_floor > tower_data.max_floor:
		handle_victory()
		return
	
	print("Advanced to floor: ", tower_data.current_floor)
	generate_current_floor_choices()
	emit_ui_update()

func handle_victory():
	var victory_message = """
恭喜完成整个塔的挑战!

最终统计:
楼层: %d/%d
战斗胜利: %d 次
总伤害: %d
卡牌总数: %d
遗物数量: %d

感谢游玩!
""" % [
		tower_data.current_floor - 1,
		tower_data.max_floor,
		GameData.battles_won,
		GameData.total_damage_dealt,
		GameData.player_deck.size(),
		GameData.player_relics.size()
	]
	
	var dialog = AcceptDialog.new()
	dialog.dialog_text = victory_message
	dialog.title = "胜利!"
	get_tree().current_scene.add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		dialog.queue_free()
		# 重置游戏或返回主菜单
		GameData.reset_game()
		SceneManager.load_tower_scene()
	)

func save_to_game_data():
	GameData.current_floor = tower_data.current_floor
	GameData.player_hp = tower_data.player_hp
	GameData.player_max_hp = tower_data.player_max_hp

func emit_ui_update():
	var data = {
		"current_floor": tower_data.current_floor,
		"max_floor": tower_data.max_floor,
		"player_hp": tower_data.player_hp,
		"player_max_hp": tower_data.player_max_hp,
		"deck_summary": GameData.get_deck_summary(),
		"player_status": GameData.get_player_status_summary()
	}
	print("Emitting UI update: ", data)
	ui_update_requested.emit(data)

# 从战斗/其他界面返回后调用
func on_battle_completed():
	# 恢复状态
	restore_from_game_data()
	advance_floor()

func _on_rest_completed():
	print("Rest completed, advancing floor")
	advance_floor()

func _on_shop_closed():
	print("Shop closed, advancing floor")
	advance_floor()

# 调试功能
func debug_advance_floor():
	advance_floor()

func debug_reset_game():
	GameData.reset_game()
	tower_data.current_floor = 1
	tower_data.player_hp = 80
	tower_data.player_max_hp = 80
	generate_current_floor_choices()
	emit_ui_update()
