extends Control

# 卡牌UI组件 - 只负责显示和交互
class_name CardUI

signal card_played(card_data: Dictionary, card_ui: CardUI)

@export var card_name_label_path: NodePath
@export var cost_label_path: NodePath
@export var description_label_path: NodePath
@export var card_background_path: NodePath

var card_name_label: Label
var cost_label: Label
var description_label: Label
var card_background: Control

var card_data: Dictionary = {}
var is_dragging: bool = false
var original_position: Vector2
var original_parent: Control

const HOVER_SCALE = Vector2(1.1, 1.1)
const NORMAL_SCALE = Vector2(1.0, 1.0)
const DRAG_Z_INDEX = 100

func _ready():
	setup_ui_references()
	connect_mouse_events()

func setup_ui_references():
	if card_name_label_path:
		card_name_label = get_node(card_name_label_path)
	if cost_label_path:
		cost_label = get_node(cost_label_path)
	if description_label_path:
		description_label = get_node(description_label_path)
	if card_background_path:
		card_background = get_node(card_background_path)

func connect_mouse_events():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func setup_card(data: Dictionary):
	card_data = data
	update_display()

func update_display():
	if card_name_label:
		card_name_label.text = card_data.get("name", "未知")
	
	if cost_label:
		cost_label.text = str(card_data.get("cost", 0))
	
	if description_label:
		description_label.text = generate_description()
	
	update_card_appearance()

func generate_description() -> String:
	var desc = ""
	
	if card_data.has("damage"):
		desc += "造成 %d 点伤害" % card_data.damage
	
	if card_data.has("block"):
		if desc != "":
			desc += "\n"
		desc += "获得 %d 点护甲" % card_data.block
	
	if card_data.has("heal"):
		if desc != "":
			desc += "\n"
		desc += "恢复 %d 点生命" % card_data.heal
	
	if card_data.has("energy"):
		if desc != "":
			desc += "\n"
		desc += "获得 %d 点能量" % card_data.energy
	
	return desc

func update_card_appearance():
	if not card_background:
		return
	
	# 根据卡牌类型设置颜色
	match card_data.get("type", ""):
		"attack":
			card_background.modulate = Color.LIGHT_CORAL
		"skill":
			card_background.modulate = Color.LIGHT_BLUE
		"power":
			card_background.modulate = Color.LIGHT_GREEN
		_:
			card_background.modulate = Color.WHITE

func _on_mouse_entered():
	if not is_dragging:
		animate_hover(true)

func _on_mouse_exited():
	if not is_dragging:
		animate_hover(false)

func animate_hover(hover: bool):
	var target_scale = HOVER_SCALE if hover else NORMAL_SCALE
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.1)
	z_index = 10 if hover else 0

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion and is_dragging:
		handle_drag(event)

func handle_mouse_button(event: InputEventMouseButton):
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if event.pressed:
		start_drag()
	else:
		end_drag()

func start_drag():
	is_dragging = true
	original_position = global_position
	original_parent = get_parent()
	z_index = DRAG_Z_INDEX
	
	# 将卡牌移动到顶层以便拖拽
	reparent(get_tree().current_scene)

func handle_drag(event: InputEventMouseMotion):
	global_position += event.relative

func end_drag():
	if not is_dragging:
		return
	
	is_dragging = false
	
	if is_in_play_area():
		play_card_action()
	else:
		return_to_hand()

func is_in_play_area() -> bool:
	var viewport = get_viewport()
	if not viewport:
		return false
	
	var viewport_size = viewport.size
	return global_position.y < viewport_size.y * 0.6

func play_card_action():
	card_played.emit(card_data, self)

func return_to_hand():
	# 返回到原来的父容器
	if original_parent and is_instance_valid(original_parent):
		reparent(original_parent)
		
		var tween = create_tween()
		tween.parallel().tween_property(self, "position", original_position, 0.3)
		tween.parallel().tween_property(self, "scale", NORMAL_SCALE, 0.2)
	
	z_index = 0

func set_interactable(enabled: bool):
	mouse_filter = Control.MOUSE_FILTER_IGNORE if not enabled else Control.MOUSE_FILTER_PASS
