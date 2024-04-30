extends VBoxContainer

var refresh_state_timer: Timer

@onready var dialogue_text_gen: DialogueTextGeneration = get_tree().get_first_node_in_group("g_dialogue_text_gen")
@onready var dialogue_speech_gen: DialogueSpeechGeneration = get_tree().get_first_node_in_group("g_dialogue_speech_gen")

@onready var text_gen_state_l: Label = $ConnectionStateContainer/TextGenContainer/StateLabel
@onready var tts_state_l: Label = $ConnectionStateContainer/TtsContainer/StateLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_state_timer = Timer.new()
	refresh_state_timer.autostart = true
	refresh_state_timer.one_shot = false
	refresh_state_timer.timeout.connect(_on_refresh_state_timer_timeout)
	add_child(refresh_state_timer)
	
	_refresh_conn_states()


func _on_refresh_state_timer_timeout():
	_refresh_conn_states()


func _refresh_conn_states():
	var text_gen = dialogue_text_gen.get_connection_state()
	var tts = dialogue_speech_gen.get_connection_state()
	
	if text_gen:
		text_gen_state_l.text = "Connected"
		text_gen_state_l.label_settings.font_color = Color.GREEN
	else:
		text_gen_state_l.text = "Not Connected"
		text_gen_state_l.label_settings.font_color = Color.RED
	
	if tts:
		tts_state_l.text = "Connected"
		tts_state_l.label_settings.font_color = Color.GREEN
	else:
		tts_state_l.text = "Not Connected"
		tts_state_l.label_settings.font_color = Color.RED


func _on_reconnect_text_gen_button_pressed():
	dialogue_text_gen.reconnect()
	_refresh_conn_states()


func _on_reconnect_tts_button_pressed():
	dialogue_speech_gen.reconnect()
	_refresh_conn_states()
