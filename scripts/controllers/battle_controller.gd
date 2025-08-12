extends Node

# 打牌场景控制器 - 纯逻辑，不依赖UI节点
class_name BattleController

signal battle_won
signal battle_lost
signal ui_update_requested(data)
signal log_message(message)

var player: Player
var enemy: Enemy
var deck_manager: DeckManager
var turn_manager: TurnManager

var is_battle_active = true

func _ready():
	# 延迟初始化确保所有节点都准备好
	call_deferred("initialize_battle")

func initialize_battle():
	print("Initializing battle...")
	
	# 创建游戏对象
	player = Player.new()
	deck_manager = DeckManager.new()
	turn_manager = TurnManager.new()
	
	# 根据全局数据创建敌人
	create_enemy_from_data()
	
	# 连接信号
	connect_signals()
	
	# 初始化数据
	setup_initial_state()
	
	# 延迟开始战斗，确保UI已经准备好
	await get_tree().process_frame
	start_battle()

func create_enemy_from_data():
	var enemy_data = GameData.get_current_enemy_data()
	if enemy_data.has("enemy_id"):
		enemy = Enemy.create_enemy(enemy_data.enemy_id)
		print("Created enemy from data: ", enemy.enemy_name)
	else:
		# 默认敌人
		enemy = Enemy.new()
		enemy.initialize(50, 50, "测试敌人")
		print("Created default enemy")

func connect_signals():
	player.health_changed.connect(_on_player_health_changed)
	player.energy_changed.connect(_on_player_energy_changed)
	player.block_changed.connect(_on_player_block_changed)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.died.connect(_on_enemy_died)
	enemy.intent_changed.connect(_on_enemy_intent_changed)
	player.died.connect(_on_player_died)
	
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	
	print("Battle controller signals connected")

func setup_initial_state():
	# 从全局数据恢复玩家状态
	player.initialize(GameData.player_hp, GameData.player_max_hp, 3, 3)
	
	# 使用玩家的卡组
	deck_manager.initialize_from_game_data(GameData.player_deck)
	
	print("Battle initial state set up")
	print("Player HP: ", player.current_health, "/", player.max_health)
	print("Player Energy: ", player.current_energy, "/", player.max_energy)
	print("Enemy HP: ", enemy.current_health, "/", enemy.max_health)
	print("Deck size: ", deck_manager.get_deck_status().deck_size)

func start_battle():
	print("Starting battle...")
	log_message.emit("战斗开始! 面对 " + enemy.enemy_name)
	
	# 抽取初始手牌
	deck_manager.draw_starting_hand()
	print("Drew starting hand, hand size: ", deck_manager.get_hand_cards().size())
	
	# 开始玩家回合
	turn_manager.start_player_turn()
	
	# 发送UI更新
	emit_ui_update()
	print("Battle started, UI update emitted")

func play_card(card_data: Dictionary) -> bool:
	print("Attempting to play card: ", card_data)
	
	if not is_battle_active or not turn_manager.is_player_turn():
		print("Cannot play card - battle inactive or not player turn")
		return false
	
	if not player.can_afford_card(card_data.cost):
		log_message.emit("能量不足!")
		print("Cannot afford card, cost: ", card_data.cost, " current energy: ", player.current_energy)
		return false
	
	# 消耗能量
	player.spend_energy(card_data.cost)
	print("Spent energy, remaining: ", player.current_energy)
	
	# 执行卡牌效果
	execute_card_effect(card_data)
	
	# 移动卡牌到弃牌堆
	deck_manager.play_card(card_data)
	
	# 记录统计
	GameData.record_card_played()
	
	emit_ui_update()
	print("Card played successfully")
	return true

func execute_card_effect(card_data: Dictionary):
	print("Executing card effect: ", card_data)
	match card_data.type:
		"attack":
			var damage = card_data.get("damage", 0)
			
			# 应用遗物加成
			damage = apply_damage_bonuses(damage)
			
			enemy.take_damage(damage)
			GameData.record_damage_dealt(damage)
			log_message.emit("对 " + enemy.enemy_name + " 造成 %d 点伤害" % damage)
			
			# 处理特殊效果
			if card_data.has("vulnerable"):
				log_message.emit(enemy.enemy_name + " 变得脆弱")
			if card_data.has("times") and card_data.times > 1:
				log_message.emit("连击 %d 次!" % card_data.times)
			if card_data.has("heal") and card_data.name == "吸血":
				player.heal(card_data.heal)
				log_message.emit("吸血恢复了 %d 点生命" % card_data.heal)
		
		"skill":
			if card_data.has("block"):
				var block = card_data.get("block", 0)
				block = apply_block_bonuses(block)
				player.add_block(block)
				log_message.emit("获得 %d 点护甲" % block)
			
			if card_data.has("heal"):
				player.heal(card_data.heal)
				log_message.emit("恢复 %d 点生命" % card_data.heal)
			
			if card_data.has("energy"):
				player.add_energy(card_data.energy)
				log_message.emit("获得 %d 点能量" % card_data.energy)
			
			if card_data.has("draw"):
				deck_manager.draw_cards(card_data.draw)
				log_message.emit("抽取 %d 张卡牌" % card_data.draw)
		
		"power":
			apply_power_effect(card_data)

func apply_damage_bonuses(base_damage: int) -> int:
	var final_damage = base_damage
	
	# 检查力量相关遗物
	for relic in GameData.player_relics:
		if relic.get("effect") == "damage_bonus":
			final_damage += relic.get("value", 0)
	
	return final_damage

func apply_block_bonuses(base_block: int) -> int:
	var final_block = base_block
	
	# 这里可以添加护甲相关的遗物加成
	return final_block

func apply_power_effect(card_data: Dictionary):
	match card_data.name:
		"狂暴":
			if card_data.has("strength"):
				log_message.emit("获得 %d 点力量!" % card_data.strength)
				# 这里可以实现力量系统
		"金属化":
			if card_data.has("permanent_block"):
				log_message.emit("获得永久护甲!")
				# 这里可以实现永久护甲系统

func end_player_turn():
	if not turn_manager.is_player_turn():
		print("Cannot end turn - not player turn")
		return
	
	print("Ending player turn...")
	turn_manager.end_player_turn()
	log_message.emit("玩家回合结束")
	
	# 延迟执行敌人回合
	await get_tree().create_timer(1.0).timeout
	execute_enemy_turn()

func execute_enemy_turn():
	print("Executing enemy turn...")
	log_message.emit(enemy.enemy_name + " 的回合开始")
	
	# 敌人回合开始处理
	enemy.start_new_turn()
	
	# 执行敌人行动
	var action_result = enemy.execute_turn()
	
	if action_result.damage > 0:
		player.take_damage(action_result.damage)
		GameData.record_damage_taken(action_result.damage)
		log_message.emit(enemy.enemy_name + " 使用 " + action_result.name + " 造成 %d 点伤害" % action_result.damage)
	
	if action_result.block > 0:
		log_message.emit(enemy.enemy_name + " 使用 " + action_result.name + " 获得 %d 点护甲" % action_result.block)
	
	await get_tree().create_timer(1.5).timeout
	
	if not is_battle_active:
		return
	
	turn_manager.start_player_turn()
	
	# 玩家回合开始时的处理
	player.start_new_turn()
	apply_turn_start_effects()
	deck_manager.draw_card()
	
	log_message.emit("你的回合开始")
	print("Player turn started, hand size: ", deck_manager.get_hand_cards().size())
	emit_ui_update()

func apply_turn_start_effects():
	# 应用回合开始的遗物效果
	for relic in GameData.player_relics:
		if relic.get("effect") == "turn_armor":
			var armor_amount = relic.get("value", 0)
			player.add_block(armor_amount)
			log_message.emit("遗物效果: 获得 %d 点护甲" % armor_amount)

func _on_player_health_changed():
	emit_ui_update()

func _on_player_energy_changed():
	emit_ui_update()

func _on_player_block_changed():
	emit_ui_update()

func _on_enemy_health_changed():
	emit_ui_update()

func _on_enemy_intent_changed():
	emit_ui_update()

func _on_enemy_died():
	is_battle_active = false
	log_message.emit("击败了 " + enemy.enemy_name + "!")
	
	# 保存玩家状态到全局数据
	GameData.player_hp = player.current_health
	GameData.player_max_hp = player.max_health
	GameData.record_battle_won()
	
	await get_tree().create_timer(2.0).timeout
	
	# 显示卡牌奖励
	show_card_rewards()

func show_card_rewards():
	var enemy_data = GameData.get_current_enemy_data()
	var enemy_type = "normal"
	
	# 根据敌人数据确定类型
	if enemy_data.has("type"):
		enemy_type = enemy_data.type
	elif enemy_data.has("enemy_id"):
		var enemy_id = enemy_data.enemy_id
		if enemy_id.begins_with("boss_"):
			enemy_type = "boss"
		elif enemy_id in ["orc_chief", "shadow_assassin"]:
			enemy_type = "elite"
	
	# 生成奖励卡牌
	var rewards = CardRewards.get_battle_rewards(enemy_type, GameData.current_floor)
	rewards = CardRewards.filter_existing_cards(rewards, GameData.player_deck)
	
	print("Generated ", rewards.size(), " reward cards")
	
	# 显示奖励界面
	var reward_ui = CardRewardUI.show_card_rewards(get_tree().current_scene, rewards)
	reward_ui.reward_confirmed.connect(_on_reward_confirmed)
	reward_ui.reward_skipped.connect(_on_reward_skipped)

func _on_reward_confirmed(card_data: Dictionary):
	print("Player selected reward: ", card_data.name)
	GameData.add_card_to_deck(card_data)
	log_message.emit("获得了新卡牌: " + card_data.name)
	
	await get_tree().create_timer(1.0).timeout
	battle_won.emit()

func _on_reward_skipped():
	print("Player skipped reward")
	log_message.emit("跳过了卡牌奖励")
	
	await get_tree().create_timer(1.0).timeout
	battle_won.emit()

func _on_player_died():
	is_battle_active = false
	log_message.emit("你被 " + enemy.enemy_name + " 击败了...")
	battle_lost.emit()

func _on_turn_started(is_player: bool):
	if is_player:
		log_message.emit("你的回合")
	else:
		log_message.emit(enemy.enemy_name + " 的回合")

func _on_turn_ended(is_player: bool):
	pass

func emit_ui_update():
	var hand_cards = deck_manager.get_hand_cards()
	var enemy_status = enemy.get_status()
	var data = {
		"player_hp": player.current_health,
		"player_max_hp": player.max_health,
		"player_energy": player.current_energy,
		"player_max_energy": player.max_energy,
		"player_block": player.current_block,
		"enemy_hp": enemy.current_health,
		"enemy_max_hp": enemy.max_health,
		"enemy_block": enemy.current_block,
		"enemy_name": enemy.enemy_name,
		"enemy_intent": enemy_status.current_intent,
		"hand_cards": hand_cards,
		"is_player_turn": turn_manager.is_player_turn(),
		"deck_status": deck_manager.get_deck_status()
	}
	
	print("Emitting UI update - hand cards: ", hand_cards.size())
	ui_update_requested.emit(data)

func get_hand_cards() -> Array:
	return deck_manager.get_hand_cards()

# 调试功能
func debug_win_battle():
	if is_battle_active:
		enemy.current_health = 0
		enemy.died.emit()

func debug_add_energy():
	if is_battle_active:
		player.add_energy(1)

func debug_heal_player():
	if is_battle_active:
		player.heal(10)
