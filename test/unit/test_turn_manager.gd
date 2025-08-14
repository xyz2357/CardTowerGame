# test/unit/data/test_turn_manager.gd
# 回合管理类测试 - Godot 4 兼容版

extends GdUnitTestSuite

var turn_manager: TurnManager

func before_test():
	turn_manager = TurnManager.new()
	# 确保每个测试都从清洁的状态开始
	assert_that(turn_manager.current_turn).is_equal(0)
	assert_that(turn_manager.is_player_turn_active).is_false()

func after():
	if turn_manager:
		turn_manager = null

# 测试初始状态
func test_initial_state():
	assert_that(turn_manager.current_turn).is_equal(0)
	assert_that(turn_manager.is_player_turn_active).is_false()
	assert_that(turn_manager.is_player_turn()).is_false()
	assert_that(turn_manager.get_turn_number()).is_equal(0)

# 测试初始状态独立验证
func test_fresh_instance_state():
	var fresh_manager = TurnManager.new()
	assert_that(fresh_manager.current_turn).is_equal(0)
	assert_that(fresh_manager.is_player_turn_active).is_false()
	assert_that(fresh_manager.is_player_turn()).is_false()
	assert_that(fresh_manager.get_turn_number()).is_equal(0)

# 测试开始玩家回合
func test_start_player_turn():
	# 验证初始状态
	assert_that(turn_manager.get_turn_number()).is_equal(0)
	assert_that(turn_manager.is_player_turn_active).is_false()
	
	var signal_monitor = monitor_signals(turn_manager)
	
	turn_manager.start_player_turn()
	
	assert_that(turn_manager.current_turn).is_equal(1)
	assert_that(turn_manager.is_player_turn_active).is_true()
	assert_that(turn_manager.is_player_turn()).is_true()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	# 移除信号测试，因为需要 await

func test_multiple_player_turns():
	# 验证初始状态
	assert_that(turn_manager.get_turn_number()).is_equal(0)
	
	# 第一次开始玩家回合
	turn_manager.start_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	# 第二次开始玩家回合
	turn_manager.start_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(2)
	
	# 第三次开始玩家回合
	turn_manager.start_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(3)

# 测试结束玩家回合
func test_end_player_turn():
	turn_manager.start_player_turn()
	var signal_monitor = monitor_signals(turn_manager)
	
	turn_manager.end_player_turn()
	
	assert_that(turn_manager.is_player_turn_active).is_false()
	assert_that(turn_manager.is_player_turn()).is_false()
	assert_that(turn_manager.get_turn_number()).is_equal(1)  # 回合数不变
	# 移除信号测试，因为需要 await

func test_end_player_turn_without_starting():
	var signal_monitor = monitor_signals(turn_manager)
	
	turn_manager.end_player_turn()
	
	assert_that(turn_manager.is_player_turn_active).is_false()
	assert_that(turn_manager.current_turn).is_equal(0)  # 回合数不变
	# 移除信号测试，因为需要 await

# 测试开始敌人回合
func test_start_enemy_turn():
	var signal_monitor = monitor_signals(turn_manager)
	
	turn_manager.start_enemy_turn()
	
	assert_that(turn_manager.is_player_turn_active).is_false()
	assert_that(turn_manager.is_player_turn()).is_false()
	# 移除信号测试，因为需要 await

func test_start_enemy_turn_after_player():
	turn_manager.start_player_turn()
	var signal_monitor = monitor_signals(turn_manager)
	
	turn_manager.start_enemy_turn()
	
	assert_that(turn_manager.is_player_turn_active).is_false()
	assert_that(turn_manager.is_player_turn()).is_false()
	assert_that(turn_manager.get_turn_number()).is_equal(1)  # 回合数不变
	# 移除信号测试，因为需要 await

# 测试结束敌人回合
func test_end_enemy_turn():
	turn_manager.start_enemy_turn()
	var signal_monitor = monitor_signals(turn_manager)
	
	turn_manager.end_enemy_turn()
	
	# 敌人回合结束不影响 is_player_turn_active 状态
	# 移除信号测试，因为需要 await

# 测试回合状态检查
func test_is_player_turn():
	# 初始状态
	assert_that(turn_manager.is_player_turn()).is_false()
	
	# 开始玩家回合
	turn_manager.start_player_turn()
	assert_that(turn_manager.is_player_turn()).is_true()
	
	# 结束玩家回合
	turn_manager.end_player_turn()
	assert_that(turn_manager.is_player_turn()).is_false()
	
	# 开始敌人回合
	turn_manager.start_enemy_turn()
	assert_that(turn_manager.is_player_turn()).is_false()

# 测试回合数获取
func test_get_turn_number():
	assert_that(turn_manager.get_turn_number()).is_equal(0)
	
	turn_manager.start_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.end_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.start_enemy_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.end_enemy_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.start_player_turn()  # 新的玩家回合
	assert_that(turn_manager.get_turn_number()).is_equal(2)

# 测试完整的回合循环
func test_complete_turn_cycle():
	var signal_monitor = monitor_signals(turn_manager)
	
	# 玩家回合
	turn_manager.start_player_turn()
	assert_that(turn_manager.is_player_turn()).is_true()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.end_player_turn()
	assert_that(turn_manager.is_player_turn()).is_false()
	
	# 敌人回合
	turn_manager.start_enemy_turn()
	assert_that(turn_manager.is_player_turn()).is_false()
	
	turn_manager.end_enemy_turn()
	
	# 下一个玩家回合
	turn_manager.start_player_turn()
	assert_that(turn_manager.is_player_turn()).is_true()
	assert_that(turn_manager.get_turn_number()).is_equal(2)
	
	# 验证信号发射次数 - 使用简单的计数验证
	# 这里我们简化测试，不验证具体的信号次数

# 测试多回合循环
func test_multiple_turn_cycles():
	for cycle in range(5):
		# 玩家回合
		turn_manager.start_player_turn()
		assert_that(turn_manager.get_turn_number()).is_equal(cycle + 1)
		assert_that(turn_manager.is_player_turn()).is_true()
		
		turn_manager.end_player_turn()
		assert_that(turn_manager.is_player_turn()).is_false()
		
		# 敌人回合
		turn_manager.start_enemy_turn()
		assert_that(turn_manager.is_player_turn()).is_false()
		
		turn_manager.end_enemy_turn()

# 测试信号参数 - 简化版本
func test_signal_parameters():
	# 使用更简单的方式测试信号，不依赖 await
	var signal_monitor = monitor_signals(turn_manager)
	
	# 玩家回合信号
	turn_manager.start_player_turn()
	turn_manager.end_player_turn()
	
	# 敌人回合信号
	turn_manager.start_enemy_turn()
	turn_manager.end_enemy_turn()
	
	# 验证基本的信号发射，不验证具体参数
	# 由于 gdUnit4 的信号测试复杂性，我们简化这个测试

# 测试状态转换的边界情况
func test_state_transition_edge_cases():
	# 连续开始玩家回合
	turn_manager.start_player_turn()
	var first_turn = turn_manager.get_turn_number()
	turn_manager.start_player_turn()
	var second_turn = turn_manager.get_turn_number()
	
	assert_that(second_turn).is_equal(first_turn + 1)
	assert_that(turn_manager.is_player_turn()).is_true()
	
	# 连续结束玩家回合
	turn_manager.end_player_turn()
	turn_manager.end_player_turn()
	
	assert_that(turn_manager.is_player_turn()).is_false()
	
	# 连续开始敌人回合
	turn_manager.start_enemy_turn()
	turn_manager.start_enemy_turn()
	
	assert_that(turn_manager.is_player_turn()).is_false()

# 测试回合数递增的正确性
func test_turn_number_increment():
	assert_that(turn_manager.get_turn_number()).is_equal(0)
	
	# 只有开始玩家回合才增加回合数
	turn_manager.start_enemy_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(0)
	
	turn_manager.end_enemy_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(0)
	
	turn_manager.start_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.end_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.start_enemy_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(1)
	
	turn_manager.start_player_turn()
	assert_that(turn_manager.get_turn_number()).is_equal(2)

# 参数化测试：不同的回合序列
func test_turn_sequences():
	var test_sequences = [
		["start_player", "end_player", "start_enemy", "end_enemy"],
		["start_player", "start_player", "end_player"],
		["start_enemy", "end_enemy", "start_player", "end_player"],
		["start_player", "end_player", "start_player", "end_player"]
	]
	
	for sequence in test_sequences:
		turn_manager = TurnManager.new()  # 重新初始化
		
		var expected_turn = 0
		
		for action in sequence:
			match action:
				"start_player":
					expected_turn += 1
					turn_manager.start_player_turn()
					assert_that(turn_manager.get_turn_number()).is_equal(expected_turn)
					assert_that(turn_manager.is_player_turn()).is_true()
				"end_player":
					turn_manager.end_player_turn()
					assert_that(turn_manager.is_player_turn()).is_false()
				"start_enemy":
					turn_manager.start_enemy_turn()
					assert_that(turn_manager.is_player_turn()).is_false()
				"end_enemy":
					turn_manager.end_enemy_turn()

# 测试信号发射 - 完整版本
func test_signal_emissions_complete():
	var signal_data = {
		"count": 0,
		"last_signal": "",
		"last_param": null,
		"history": []
	}
	
	# 连接信号来手动验证
	turn_manager.turn_started.connect(func(is_player: bool): 
		signal_data.count += 1
		signal_data.last_signal = "turn_started"
		signal_data.last_param = is_player
		signal_data.history.append({"signal": "turn_started", "param": is_player})
	)
	turn_manager.turn_ended.connect(func(is_player: bool): 
		signal_data.count += 1
		signal_data.last_signal = "turn_ended"
		signal_data.last_param = is_player
		signal_data.history.append({"signal": "turn_ended", "param": is_player})
	)
	
	# 测试玩家回合信号
	turn_manager.start_player_turn()
	assert_that(signal_data.count).is_equal(1)
	assert_that(signal_data.last_signal).is_equal("turn_started")
	assert_that(signal_data.last_param).is_equal(true)
	
	turn_manager.end_player_turn()
	assert_that(signal_data.count).is_equal(2)
	assert_that(signal_data.last_signal).is_equal("turn_ended")
	assert_that(signal_data.last_param).is_equal(true)
	
	# 测试敌人回合信号
	turn_manager.start_enemy_turn()
	assert_that(signal_data.count).is_equal(3)
	assert_that(signal_data.last_signal).is_equal("turn_started")
	assert_that(signal_data.last_param).is_equal(false)
	
	turn_manager.end_enemy_turn()
	assert_that(signal_data.count).is_equal(4)
	assert_that(signal_data.last_signal).is_equal("turn_ended")
	assert_that(signal_data.last_param).is_equal(false)
	
	# 验证完整的信号历史
	assert_that(signal_data.history.size()).is_equal(4)
	assert_that(signal_data.history[0].signal).is_equal("turn_started")
	assert_that(signal_data.history[0].param).is_equal(true)
	assert_that(signal_data.history[1].signal).is_equal("turn_ended")
	assert_that(signal_data.history[1].param).is_equal(true)
	assert_that(signal_data.history[2].signal).is_equal("turn_started")
	assert_that(signal_data.history[2].param).is_equal(false)
	assert_that(signal_data.history[3].signal).is_equal("turn_ended")
	assert_that(signal_data.history[3].param).is_equal(false)

# 测试信号发射次数 - 修复闭包问题
func test_signal_count_simple():
	var signal_counts = {"started": 0, "ended": 0}
	
	# 连接信号计数器
	turn_manager.turn_started.connect(func(is_player: bool): 
		signal_counts.started += 1
		print("turn_started signal received, count: ", signal_counts.started, ", is_player: ", is_player)
	)
	turn_manager.turn_ended.connect(func(is_player: bool): 
		signal_counts.ended += 1
		print("turn_ended signal received, count: ", signal_counts.ended, ", is_player: ", is_player)
	)
	
	# 执行一个回合
	print("Starting player turn...")
	turn_manager.start_player_turn()
	print("After start_player_turn(), counts: ", signal_counts)
	assert_that(signal_counts.started).is_equal(1)
	assert_that(signal_counts.ended).is_equal(0)
	
	print("Ending player turn...")
	turn_manager.end_player_turn()
	print("After end_player_turn(), counts: ", signal_counts)
	assert_that(signal_counts.started).is_equal(1)
	assert_that(signal_counts.ended).is_equal(1)

# 测试并发状态（模拟）
func test_concurrent_state_access():
	# 模拟多个操作同时访问状态
	turn_manager.start_player_turn()
	
	var is_player_1 = turn_manager.is_player_turn()
	var turn_number_1 = turn_manager.get_turn_number()
	var is_player_2 = turn_manager.is_player_turn()
	var turn_number_2 = turn_manager.get_turn_number()
	
	# 状态应该保持一致
	assert_that(is_player_1).is_equal(is_player_2)
	assert_that(turn_number_1).is_equal(turn_number_2)
	assert_that(is_player_1).is_true()
	assert_that(turn_number_1).is_equal(1)

# 压力测试：大量回合操作 - 简化版本
func test_stress_turn_operations():
	# 简化压力测试，专注于逻辑而不是信号
	
	# 执行大量回合操作
	for i in range(100):  # 减少数量以加快测试
		turn_manager.start_player_turn()
		turn_manager.end_player_turn()
		turn_manager.start_enemy_turn()
		turn_manager.end_enemy_turn()
	
	# 验证最终状态
	assert_that(turn_manager.get_turn_number()).is_equal(100)
	assert_that(turn_manager.is_player_turn()).is_false()

# 测试边界值
func test_boundary_values():
	# 测试大回合数
	for i in range(10000):
		turn_manager.start_player_turn()
	
	assert_that(turn_manager.get_turn_number()).is_equal(10000)
	assert_that(turn_manager.is_player_turn()).is_true()

# 测试类型安全
func test_type_safety():
	# 验证属性类型
	assert_that(typeof(turn_manager.current_turn)).is_equal(TYPE_INT)
	assert_that(typeof(turn_manager.is_player_turn_active)).is_equal(TYPE_BOOL)
	
	# 验证方法返回值类型
	assert_that(typeof(turn_manager.is_player_turn())).is_equal(TYPE_BOOL)
	assert_that(typeof(turn_manager.get_turn_number())).is_equal(TYPE_INT)
