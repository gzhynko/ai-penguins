class_name PresentQueueContainer
extends PanelContainer

@onready var enqueued_list: ItemList = $VBoxContainer/EnqueuedList

@onready var presentation_manager: PresentationManager = get_tree().get_first_node_in_group("g_presentation_man")


func _ready():
	presentation_manager.present_queue_updated.connect(_on_present_queue_updated)
	presentation_manager.current_presented_updated.connect(_on_current_presented_updated)


func _on_current_presented_updated(_new_presented: CompleteDialogue):
	var queue = presentation_manager.present_queue
	_on_present_queue_updated(queue)


func _on_present_queue_updated(new_queue: Dictionary):
	enqueued_list.clear()
	
	var queue_array = []
	if _is_any_presented_now():
		queue_array.push_back([0, presentation_manager.current_presented.topic])
	for i in range(new_queue.keys().size()):
		queue_array.push_back([new_queue.keys()[i], new_queue.values()[i].topic])

	for i in range(queue_array.size()):
		var queue_item = queue_array[i]
		var dialogue_id = queue_item[0]
		var topic = queue_item[1]
		
		if i == 0 and _is_any_presented_now() and presentation_manager.current_presented.topic == topic:
			var item_text = "(LIVE NOW) {0}".format([topic])
			var list_item_id = enqueued_list.add_item(item_text, null, true)
			enqueued_list.set_item_disabled(list_item_id, true)
		else:
			var item_text = "{0} (id {1})".format([topic, dialogue_id])
			var list_item_id = enqueued_list.add_item(item_text, null, true)
			enqueued_list.set_item_metadata(list_item_id, dialogue_id)


func _is_any_presented_now() -> bool:
	return presentation_manager.current_presented != null


func _on_remove_button_pressed():
	var selected = enqueued_list.get_selected_items()
	var topic_ids_to_remove = []
	for id in selected:
		if enqueued_list.is_item_disabled(id):
			continue
		
		var topic_id = enqueued_list.get_item_metadata(id)
		topic_ids_to_remove.push_back(topic_id)
	for topic_id in topic_ids_to_remove:
		presentation_manager.remove.emit(topic_id)


func _get_id_of_item(topic_id: int) -> int:
	for i in range(enqueued_list.item_count):
		if enqueued_list.get_item_metadata(i) == topic_id:
			return i
	return 0
