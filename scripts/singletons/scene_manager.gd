extends Node

# 场景管理器 - 统一管理场景切换
# 设置为AutoLoad单例

const MAIN_MENU_SCENE_PATH = "res://scenes/main_menu.tscn"
const TOWER_SCENE_PATH = "res://scenes/tower_scene.tscn"
const BATTLE_SCENE_PATH = "res://scenes/battle_scene.tscn"

# 场景转换效果
var is_transitioning = false

func _ready():
	print("SceneManager initialized")

func load_main_menu():
	print("Loading main menu...")
	if is_transitioning:
		return
	
	transition_to_scene(MAIN_MENU_SCENE_PATH)

func load_tower_scene():
	print("Loading tower scene...")
	if is_transitioning:
		return
	
	# 自动保存游戏状态
	GameData.save_to_file()
	
	transition_to_scene(TOWER_SCENE_PATH)

func load_battle_scene(enemy_data: Dictionary = {}):
	print("Loading battle scene...")
	if is_transitioning:
		return
	
	# 保存敌人数据
	if not enemy_data.is_empty():
		GameData.set_current_enemy_data(enemy_data)
	
	# 自动保存游戏状态
	GameData.save_to_file()
	
	transition_to_scene(BATTLE_SCENE_PATH)

func transition_to_scene(scene_path: String):
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# 获取当前场景
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("Warning: current_scene is null, using direct scene change")
		var result = get_tree().change_scene_to_file(scene_path)
		is_transitioning = false
		if result != OK:
			print("Failed to load scene: ", scene_path)
		return
	
	# 简单的淡出效果
	var fade_overlay = create_fade_overlay()
	current_scene.add_child(fade_overlay)
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate", Color(0, 0, 0, 1), 0.3)
	
	await tween.finished
	
	# 切换场景
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("Failed to load scene: ", scene_path)
		is_transitioning = false
		return
	
	# 等待新场景加载
	await get_tree().process_frame
	
	# 淡入效果
	var new_current_scene = get_tree().current_scene
	if new_current_scene:
		var new_fade_overlay = create_fade_overlay()
		new_fade_overlay.modulate = Color(0, 0, 0, 1)
		new_current_scene.add_child(new_fade_overlay)
		
		var fade_in_tween = create_tween()
		fade_in_tween.tween_property(new_fade_overlay, "modulate", Color(0, 0, 0, 0), 0.3)
		
		await fade_in_tween.finished
		
		new_fade_overlay.queue_free()
	
	is_transitioning = false

func create_fade_overlay() -> ColorRect:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 1000  # 确保在最顶层
	return overlay

func reload_current_scene():
	print("Reloading current scene...")
	if is_transitioning:
		return
	
	get_tree().reload_current_scene()

func quit_game():
	print("Quitting game...")
	# 自动保存
	GameData.save_to_file()
	get_tree().quit()

# 获取当前场景名称
func get_current_scene_name() -> String:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path:
		return current_scene.scene_file_path.get_file().get_basename()
	return ""

# 检查是否在特定场景
func is_in_battle() -> bool:
	return get_current_scene_name() == "battle_scene"

func is_in_tower() -> bool:
	return get_current_scene_name() == "tower_scene"

func is_in_main_menu() -> bool:
	return get_current_scene_name() == "main_menu"

# 紧急返回主菜单（用于错误处理）
func emergency_return_to_menu():
	print("Emergency return to main menu")
	is_transitioning = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

# 全局输入处理
func _input(event):
	if event is InputEventKey and event.pressed:
		# 全局快捷键
		if event.keycode == KEY_F5:
			# F5 快速保存
			GameData.save_to_file()
			show_quick_message("游戏已保存")
		elif event.keycode == KEY_F9:
			# F9 快速载入
			if GameData.load_from_file():
				show_quick_message("游戏已载入")
				if not is_in_tower():
					load_tower_scene()
			else:
				show_quick_message("载入失败")

func show_quick_message(text: String):
	var current_scene = get_tree().current_scene
	if not current_scene:
		print("Quick message: ", text)
		return
	
	var label = Label.new()
	label.text = text
	label.modulate = Color.YELLOW
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 24)
	label.z_index = 999
	current_scene.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color.TRANSPARENT, 2.0)
	tween.tween_callback(label.queue_free)
