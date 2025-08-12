extends Control

# 主菜单UI控制器
class_name MainMenuUI

var new_game_button: Button
var continue_button: Button
var settings_button: Button
var quit_button: Button
var stats_label: Label
var title_label: Label

func _ready():
	setup_ui_references()
	connect_signals()
	update_display()
	setup_title_animation()
	_ready_effects()  # 调用视觉效果设置

func setup_ui_references():
	title_label = $CenterContainer/VBoxContainer/Title
	new_game_button = $CenterContainer/VBoxContainer/NewGameButton
	continue_button = $CenterContainer/VBoxContainer/ContinueButton
	settings_button = $CenterContainer/VBoxContainer/SettingsButton
	quit_button = $CenterContainer/VBoxContainer/QuitButton
	stats_label = $CenterContainer/VBoxContainer/StatsLabel

func connect_signals():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func update_display():
	# 检查是否有存档
	var has_save = GameData.has_save_file()
	continue_button.disabled = not has_save
	
	if has_save:
		continue_button.text = "继续游戏 (楼层 %d)" % GameData.current_floor
	else:
		continue_button.text = "继续游戏 (无存档)"
	
	# 更新统计信息
	var stats = GameData.get_game_statistics()
	var stats_text = """
当前进度: 楼层 %d
战斗胜利: %d 次
总伤害: %d
已打出卡牌: %d 张
当前卡组: %d 张卡牌
拥有遗物: %d 个
""" % [
		stats.current_floor,
		stats.battles_won,
		stats.total_damage_dealt,
		stats.cards_played,
		stats.deck_size,
		stats.relics_count
	]
	
	stats_label.text = stats_text
	
	# 设置标题样式
	if title_label:
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.GOLD)

func setup_title_animation():
	if not title_label:
		return
	
	# 创建标题闪烁动画
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 0.7), 2.0)
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1.0), 2.0)

func _on_new_game_pressed():
	# 显示确认对话框
	if GameData.current_floor > 1:
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "开始新游戏将会覆盖当前进度，确定继续吗？"
		add_child(dialog)
		dialog.popup_centered()
		
		dialog.confirmed.connect(func():
			start_new_game()
			dialog.queue_free()
		)
		
		dialog.get_cancel_button().pressed.connect(func():
			dialog.queue_free()
		)
	else:
		start_new_game()

func start_new_game():
	print("Starting new game...")
	GameData.reset_game()
	GameData.save_to_file()
	SceneManager.load_tower_scene()

func _on_continue_pressed():
	if GameData.has_save_file():
		print("Loading saved game...")
		if GameData.load_from_file():
			SceneManager.load_tower_scene()
		else:
			show_error("载入存档失败")
	else:
		show_error("没有找到存档文件")

func _on_settings_pressed():
	show_settings_dialog()

func _on_quit_pressed():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "确定要退出游戏吗？"
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func():
		GameData.save_to_file()  # 自动保存
		get_tree().quit()
	)
	
	dialog.get_cancel_button().pressed.connect(func():
		dialog.queue_free()
	)

func show_settings_dialog():
	var settings_dialog = AcceptDialog.new()
	settings_dialog.title = "设置"
	settings_dialog.custom_minimum_size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	settings_dialog.add_child(vbox)
	
	# 音量设置
	vbox.add_child(Label.new())
	var master_label = Label.new()
	master_label.text = "主音量"
	vbox.add_child(master_label)
	
	var master_slider = HSlider.new()
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.value = GameData.master_volume
	vbox.add_child(master_slider)
	
	var sfx_label = Label.new()
	sfx_label.text = "音效音量"
	vbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.value = GameData.sfx_volume
	vbox.add_child(sfx_slider)
	
	# 重置进度按钮
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var reset_button = Button.new()
	reset_button.text = "重置游戏进度"
	reset_button.modulate = Color.RED
	vbox.add_child(reset_button)
	
	reset_button.pressed.connect(func():
		var confirm_dialog = ConfirmationDialog.new()
		confirm_dialog.dialog_text = "这将删除所有游戏进度，确定继续吗？"
		add_child(confirm_dialog)
		confirm_dialog.popup_centered()
		
		confirm_dialog.confirmed.connect(func():
			GameData.reset_game()
			settings_dialog.queue_free()
			confirm_dialog.queue_free()
			update_display()
		)
		
		confirm_dialog.get_cancel_button().pressed.connect(func():
			confirm_dialog.queue_free()
		)
	)
	
	# 连接滑块事件
	master_slider.value_changed.connect(func(value):
		GameData.master_volume = value
		# 这里可以设置实际的音频总线音量
	)
	
	sfx_slider.value_changed.connect(func(value):
		GameData.sfx_volume = value
		# 这里可以设置实际的音效音量
	)
	
	add_child(settings_dialog)
	settings_dialog.popup_centered()
	
	settings_dialog.confirmed.connect(func():
		GameData.save_to_file()  # 保存设置
		settings_dialog.queue_free()
	)

func show_error(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "错误"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

# 处理输入事件
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				if not continue_button.disabled:
					_on_continue_pressed()
				else:
					_on_new_game_pressed()
			KEY_ESCAPE:
				_on_quit_pressed()
			KEY_F1:
				_on_settings_pressed()

# 添加一些视觉效果
func _ready_effects():
	# 按钮悬停效果
	for button in [new_game_button, continue_button, settings_button, quit_button]:
		if button:
			button.mouse_entered.connect(func(): animate_button_hover(button, true))
			button.mouse_exited.connect(func(): animate_button_hover(button, false))

func animate_button_hover(button: Button, hover: bool):
	var target_scale = Vector2(1.05, 1.05) if hover else Vector2.ONE
	var tween = create_tween()
	tween.tween_property(button, "scale", target_scale, 0.1)
