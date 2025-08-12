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
	
	# 生成当前楼层的选择
	generate_current_floor_choices()
	emit_ui_update()

func restore_from_game_data():
	tower_data.current_floor = GameData.current_floor
	tower_data.player_hp = GameData.player_hp
	tower_data.player_max_hp = GameData.player_max_hp

func generate_current_floor_choices():
	var choices = choice_generator.generate_choices_for_floor(tower_data.current_floor)
	choices_update_requested.emit(choices)

func handle_choice_selected(choice_data: Dictionary):
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
	var rest_options = [
		{"type": "heal", "name": "恢复生命", "description": "恢复30%最大生命值"},
		{"type": "upgrade", "name": "升级卡牌", "description": "选择一张卡牌进行升级"}
	]
	# 这里可以发送休息选择信号给UI
	message_requested.emit("选择休息方式")
	advance_floor()

func handle_shop_choice():
	message_requested.emit("商店功能待实现")
	advance_floor()

func handle_treasure_choice():
	message_requested.emit("获得了稀有遗物!")
	advance_floor()

func advance_floor():
	tower_data.current_floor += 1
	
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
	ui_update_requested.emit(data)

# 从战斗返回后调用
func on_battle_completed():
	advance_floor()
