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
	battle_requested.emit(enemy_data)

func handle_rest_choice():
	var heal_amount = int(tower_data.player_max_hp * 0.3)
	tower_data.player_hp = min(tower_data.player_max_hp, tower_data.player_hp + heal_amount)
	message_requested.emit("恢复了 " + str(heal_amount) + " 点生命值")
	advance_floor()

func handle_shop_choice():
	message_requested.emit("商店功能待实现")
	advance_floor()

func handle_treasure_choice():
	message_requested.emit("获得了稀有遗物!")
	advance_floor()

func advance_floor():
	tower_data.current_floor += 1
	save_to_game_data()
	
	if tower_data.current_floor > tower_data.max_floor:
		handle_victory()
		return
	
	generate_current_floor_choices()
	emit_ui_update()

func handle_victory():
	message_requested.emit("恭喜完成整个塔的挑战!")

func save_to_game_data():
	GameData.current_floor = tower_data.current_floor
	GameData.player_hp = tower_data.player_hp
	GameData.player_max_hp = tower_data.player_max_hp

func emit_ui_update():
	var data = {
		"current_floor": tower_data.current_floor,
		"max_floor": tower_data.max_floor,
		"player_hp": tower_data.player_hp,
		"player_max_hp": tower_data.player_max_hp
	}
	print("Emitting UI update: ", data)
	ui_update_requested.emit(data)

# 从战斗返回后调用
func on_battle_completed():
	advance_floor()
