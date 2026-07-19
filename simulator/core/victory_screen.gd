extends Control

# Overlay de fim de partida em estilo letterbox: faixas escuras no topo e
# no rodapé, texto na cor do vencedor e botão de reiniciar. O vencedor em
# si NÃO é redesenhado aqui — ele continua no mapa, e o game.gd dá zoom
# da view até a posição dele.

const BAND_TOP = 150.0
const BAND_BOTTOM = 140.0
const FADE_IN_DELAY = 0.5
const FADE_IN_DURATION = 0.4
const RESTART_SECONDS = 5

var winner_id = -1  # -1 = empate
var seconds_left = RESTART_SECONDS
var countdown_label = null

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var text = "EMPATE"
	var color = Color(0.75, 0.75, 0.78)
	if winner_id >= 0:
		var names = preload("res://core/simulation.gd").PLAYER_NAMES
		text = names[winner_id].to_upper() + " VENCEU"
		color = preload("res://core/simulation_view.gd").PLAYER_COLORS[winner_id]

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", color)
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 0.0
	label.offset_bottom = BAND_TOP
	add_child(label)

	# Contagem regressiva de reinício automático, na faixa de baixo.
	countdown_label = Label.new()
	countdown_label.text = "Reiniciando em %d..." % RESTART_SECONDS
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 30)
	countdown_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	countdown_label.anchor_left = 0.0
	countdown_label.anchor_right = 1.0
	countdown_label.anchor_top = 1.0
	countdown_label.anchor_bottom = 1.0
	countdown_label.offset_top = -BAND_BOTTOM
	add_child(countdown_label)

	var countdown_timer = Timer.new()
	countdown_timer.wait_time = 1.0
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)
	countdown_timer.start()

	# Aparece suavemente depois que o zoom da câmera termina.
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_interval(FADE_IN_DELAY)
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)

func _on_countdown_tick():
	seconds_left -= 1
	if seconds_left <= 0:
		get_tree().reload_current_scene()
	else:
		countdown_label.text = "Reiniciando em %d..." % seconds_left

func _draw():
	var band_color = Color(0.02, 0.02, 0.04, 0.88)
	draw_rect(Rect2(0, 0, size.x, BAND_TOP), band_color)
	draw_rect(Rect2(0, size.y - BAND_BOTTOM, size.x, BAND_BOTTOM), band_color)

	# No empate não há vencedor pra destacar: escurece o meio também.
	if winner_id < 0:
		draw_rect(Rect2(0, BAND_TOP, size.x, size.y - BAND_TOP - BAND_BOTTOM), Color(0.02, 0.02, 0.04, 0.6))
