class_name TextGenEnqueuedContainer
extends PanelContainer

@onready var enqueued_list: ItemList = $VBoxContainer/EnqueuedList
@onready var prompt_entry_line_edit: LineEdit = $VBoxContainer/EnqueuePromptContainer/LineEdit

@onready var dialogue_text_gen: DialogueTextGeneration = get_tree().get_first_node_in_group("g_dialogue_text_gen")


# Called when the node enters the scene tree for the first time.
func _ready():
	# connect signals
	dialogue_text_gen.enqueued_topics_updated.connect(_on_enqueued_topics_updated)


func _on_enqueued_topics_updated(new_queue: Dictionary):
	enqueued_list.clear()
	for topic_id in new_queue.keys():
		var list_item_id = enqueued_list.add_item(new_queue.get(topic_id), null, true)
		enqueued_list.set_item_metadata(list_item_id, topic_id)


func _on_remove_button_pressed():
	var selected = enqueued_list.get_selected_items()
	var topic_ids_to_remove = []
	for id in selected:
		var topic_id = enqueued_list.get_item_metadata(id)
		topic_ids_to_remove.push_back(topic_id)
	for topic_id in topic_ids_to_remove:
		dialogue_text_gen.remove_topic_id(topic_id)


func _get_id_of_item(topic_id: int) -> int:
	for i in range(enqueued_list.item_count):
		if enqueued_list.get_item_metadata(i) == topic_id:
			return i
	return 0


func _on_submit_button_pressed():
	var prompt_text = prompt_entry_line_edit.text
	if prompt_text.is_empty():
		return
	
	prompt_entry_line_edit.clear()
	dialogue_text_gen.add_new_topic(prompt_text)


func _on_prompt_entry_text_submitted(_text):
	_on_submit_button_pressed()
