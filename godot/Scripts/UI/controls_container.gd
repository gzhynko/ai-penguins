extends VBoxContainer

@onready var penguins: Penguins = get_tree().get_first_node_in_group("g_penguin_man")
@onready var cam: Camera = get_tree().get_first_node_in_group("g_camera")

@onready var dialogue_speech_gen: DialogueSpeechGeneration = get_tree().get_first_node_in_group("g_dialogue_speech_gen")
@onready var dialogue_text_gen: DialogueTextGeneration = get_tree().get_first_node_in_group("g_dialogue_text_gen")


func _on_reset_cam_button_pressed():
	cam.reset_position()


func _on_reset_pengs_button_pressed():
	penguins.reset_penguins()


func _on_reset_tts_dialogue_button_pressed():
	if dialogue_speech_gen.curr_dialogue_id != -1:
		dialogue_speech_gen.cancel_generating()


func _on_reset_text_gen_button_pressed():
	if dialogue_text_gen.current_topic_id != -1:
		dialogue_text_gen.cancel_generating()
