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
	initialize_battle()

func initialize_battle():
	# 创建游戏对象
	player = Player.new()
	enemy = Enemy.new()
	deck_manager = DeckManager.new()
	turn_manager = TurnManager.new()
	
	# 连接信号
	player.health_changed.connect(_on_player_health_changed)
	player.energy_changed.connect(_on_player_energy_changed)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.died.connect(_on_enemy_died)
	player.died.connect(_on_player_died)
	
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.turn_ended.connect(_on_turn_ended)
	
	# 初始化数据
	setup_initial_state()
	start_battle()

func setup_initial_state():
	player.initialize(80, 80, 3, 3)
	enemy.initialize(50, 50)
	deck_manager.initialize_default_deck()
	
	# 发送初始UI更新
	emit_ui_update()

func start_battle():
	log_message.emit("战斗开始!")
	deck_manager.draw_starting_hand()
	turn_manager.start_player_turn()
	emit_ui_update()

func play_card(card_data: Dictionary) -> bool:
	if not is_battle_active or not turn_manager.is_player_turn():
		return false
	
	if not player.can_afford_card(card_data.cost):
		log_message.emit("能量不足!")
		return false
	
	# 消耗能量
	player.spend_energy(card_data.cost)
	
	# 执行卡牌效果
	execute_card_effect(card_data)
	
	# 移动卡牌到弃牌堆
	deck_manager.play_card(card_data)
	
	emit_ui_update()
	return true

func execute_card_effect(card_data: Dictionary):
	match card_data.type:
		"attack":
			var damage = card_data.get("damage", 0)
			enemy.take_damage(damage)
			log_message.emit("对敌人造成 %d 点伤害" % damage)
		"skill":
			if card_data.has("block"):
				player.add_block(card_data.block)
				log_message.emit("获得 %d 点护甲" % card_data.block)
			if card_data.has("heal"):
				player.heal(card_data.heal)
				log_message.emit("恢复 %d 点生命" % card_data.heal)
			if card_data.has("energy"):
				player.add_energy(card_data.energy)
				log_message.emit("获得 %d 点能量" % card_data.energy)

func end_player_turn():
	if not turn_manager.is_player_turn():
		return
	
	turn_manager.end_player_turn()
	log_message.emit("玩家回合结束")
	
	# 延迟执行敌人回合
	await get_tree().create_timer(1.0).timeout
	execute_enemy_turn()

func execute_enemy_turn():
	log_message.emit("敌人回合开始")
	
	# 简单敌人AI
	var damage = enemy.get_attack_damage()
	player.take_damage(damage)
	log_message.emit("敌人对你造成 %d 点伤害" % damage)
	
	await get_tree().create_timer(1.0).timeout
	turn_manager.start_player_turn()
	
	# 玩家回合开始时的处理
	player.start_new_turn()
	deck_manager.draw_card()
	
	emit_ui_update()

func _on_player_health_changed():
	emit_ui_update()

func _on_player_energy_changed():
	emit_ui_update()

func _on_enemy_health_changed():
	emit_ui_update()

func _on_enemy_died():
	is_battle_active = false
	log_message.emit("战斗胜利!")
	battle_won.emit()

func _on_player_died():
	is_battle_active = false
	log_message.emit("战斗失败!")
	battle_lost.emit()

func _on_turn_started(is_player: bool):
	if is_player:
		log_message.emit("你的回合开始")
	else:
		log_message.emit("敌人回合开始")

func _on_turn_ended(is_player: bool):
	pass

func emit_ui_update():
	var data = {
		"player_hp": player.current_health,
		"player_max_hp": player.max_health,
		"player_energy": player.current_energy,
		"player_max_energy": player.max_energy,
		"player_block": player.current_block,
		"enemy_hp": enemy.current_health,
		"enemy_max_hp": enemy.max_health,
		"hand_cards": deck_manager.get_hand_cards(),
		"is_player_turn": turn_manager.is_player_turn()
	}
	ui_update_requested.emit(data)

func get_hand_cards() -> Array:
	return deck_manager.get_hand_cards()
