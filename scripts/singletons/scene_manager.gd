extends Node

# 场景管理器 - 统一管理场景切换
# 设置为AutoLoad单例

const TOWER_SCENE_PATH = "res://scenes/tower_scene.tscn"
const BATTLE_SCENE_PATH = "res://scenes/battle_scene.tscn"

func load_tower_scene():
	get_tree().change_scene_to_file(TOWER_SCENE_PATH)

func load_battle_scene(enemy_data: Dictionary = {}):
	# 保存敌人数据
	if not enemy_data.is_empty():
		GameData.current_enemy_data = enemy_data
	
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)

func reload_current_scene():
	get_tree().reload_current_scene()

func quit_game():
	get_tree().quit()
