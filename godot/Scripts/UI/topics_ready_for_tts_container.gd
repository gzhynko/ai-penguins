extends PanelContainer

var current_selected_dialogue = -1

@onready var topics_list: ItemList = $VBoxContainer/HBoxContainer/TopicsList
@onready var dialogue_creation_manager: DialogueCreationManager = get_tree().get_first_node_in_group("g_dialogue_creation_man")

@onready var topic_details_container = $VBoxContainer/HBoxContainer/TopicDetailsContainer
@onready var script_text: TextEdit = topic_details_container.get_node("DialogueScriptText")
@onready var raw_lines_text: TextEdit = topic_details_container.get_node("DialogueRawLinesText")

@onready var approve_button: Button = topic_details_container.get_node("HBoxContainer/ApproveButton")
@onready var remove_button: Button = topic_details_container.get_node("HBoxContainer/RemoveButton")

@onready var auto_accept_button: CheckButton = $VBoxContainer/HBoxContainer2/AutoAcceptButton


# Called when the node enters the scene tree for the first time.
func _ready():
	dialogue_creation_manager.dialogues_ready_for_tts_changed.connect(_on_dialogues_ready_for_tts_changed)
	dialogue_creation_manager.new_dialogue_ready_for_tts.connect(_on_new_dialogue_ready_for_tts)
	topics_list.item_selected.connect(_on_topics_list_item_selected)


func _on_dialogues_ready_for_tts_changed(new: Dictionary):
	topics_list.clear()
	var keys_arr = new.keys().duplicate()
	keys_arr.reverse()
	
	if not keys_arr.has(current_selected_dialogue):
		topic_details_container.hide()
	
	for id in keys_arr:
		var dialogue: ParsedDialogue = new.get(id)
		
		var prefix_text = ""
		if dialogue.is_sent_to_tts and not dialogue.being_voiced:
			prefix_text = "(IN TTS QUEUE)"
		elif dialogue.being_voiced:
			prefix_text = "(BEING VOICED)"
		
		var text = "{3} {0} (id: {1}, lines: {2})".format([dialogue.dialogue_topic, id, dialogue.replicas_count, prefix_text])
		var list_item_id = topics_list.add_item(text, null, true)
		topics_list.set_item_metadata(list_item_id, id)
		
		if dialogue.is_sent_to_tts and not dialogue.being_voiced:
			topics_list.set_item_custom_fg_color(list_item_id, Color.PALE_TURQUOISE)
		elif dialogue.being_voiced:
			topics_list.set_item_custom_fg_color(list_item_id, Color.FOREST_GREEN)


func _on_new_dialogue_ready_for_tts(id: int):
	if auto_accept_button.is_pressed():
		dialogue_creation_manager.approve_for_tts(id)


func _on_topics_list_item_selected(item_id: int):
	var dialogue_id = topics_list.get_item_metadata(item_id)
	current_selected_dialogue = dialogue_id
	topic_details_container.show()
	
	_update_topic_details_panel(dialogue_creation_manager.is_tts_dialogue_in_queue(dialogue_id))


func _update_topic_details_panel(is_in_tts: bool):
	script_text.text = _replicas_to_string(dialogue_creation_manager.get_tts_dialogue_script(current_selected_dialogue))
	raw_lines_text.text = "\n".join(dialogue_creation_manager.get_tts_dialogue_raw_lines(current_selected_dialogue))
	
	if is_in_tts:
		approve_button.hide()
		remove_button.hide()
	else:
		approve_button.show()
		remove_button.show()


func _replicas_to_string(replicas_arr: Array[Replica]) -> String:
	var res = ""
	for r in replicas_arr:
		res += Characters.character_to_string_capitalized(r.author)
		res += ": "
		res += r.text
		res += "\n"
	return res


func _on_remove_button_pressed():
	dialogue_creation_manager.remove_dialogue_tts(current_selected_dialogue)
	current_selected_dialogue = -1
	topic_details_container.hide()


func _on_approve_button_pressed():
	topics_list.deselect_all()
	topic_details_container.hide()
	dialogue_creation_manager.approve_for_tts(current_selected_dialogue)
