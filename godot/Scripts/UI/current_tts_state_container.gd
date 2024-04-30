extends VBoxContainer

@onready var dialogue_speech_gen: DialogueSpeechGeneration = get_tree().get_first_node_in_group("g_dialogue_speech_gen")

@onready var curr_dialogue_id_line: LineEdit = $HBoxContainer/DialogueIdLine
@onready var processed_line_text: TextEdit = $ProcessedLineText


func _ready():
	dialogue_speech_gen.current_generated_dialogue_changed.connect(_on_current_generated_dialogue_changed)
	dialogue_speech_gen.current_generated_line_changed.connect(_on_current_generated_line_changed)


func _on_current_generated_dialogue_changed(new_dialogue_id: int):
	curr_dialogue_id_line.text = var_to_str(new_dialogue_id) if new_dialogue_id != -1 else ""


func _on_current_generated_line_changed(new_line: String):
	processed_line_text.text = new_line
