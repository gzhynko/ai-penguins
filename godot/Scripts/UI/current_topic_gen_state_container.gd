extends VBoxContainer

@onready var dialogue_text_gen: DialogueTextGeneration = get_tree().get_first_node_in_group("g_dialogue_text_gen")

@onready var curr_topic_text_edit: TextEdit = $CurrTopicText
@onready var gen_lines_text_edit: TextEdit = $GenLinesText


# Called when the node enters the scene tree for the first time.
func _ready():
	dialogue_text_gen.current_topic_updated.connect(_on_current_topic_updated)
	dialogue_text_gen.current_generated_lines_updated.connect(_on_current_generated_lines_updated)


func _on_current_topic_updated(_id, new_topic: String):
	curr_topic_text_edit.text = new_topic


func _on_current_generated_lines_updated(new_lines: Array[String]):
	gen_lines_text_edit.text = "\n".join(new_lines)
	gen_lines_text_edit.scroll_vertical = INF
