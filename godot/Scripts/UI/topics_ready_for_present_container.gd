extends PanelContainer

var current_selected_dialogue = -1

var voice_line_container: PackedScene = preload("res://Scenes/voice_line_container.tscn")

@onready var dialogues_list: ItemList = $VBoxContainer/HBoxContainer/DialoguesList
@onready var dialogue_creation_manager: DialogueCreationManager = get_tree().get_first_node_in_group("g_dialogue_creation_man")
@onready var test_dialogue_player: AudioStreamPlayer = get_tree().get_first_node_in_group("g_test_dialogue_player")

@onready var dialogue_details_container: VBoxContainer = $VBoxContainer/HBoxContainer/DialogueDetailsContainer
@onready var script_text: TextEdit = dialogue_details_container.get_node("DialogueScriptText")
@onready var voice_lines_container: VBoxContainer = dialogue_details_container.get_node("ScrollContainer/VBoxContainer")

@onready var auto_accept_button: CheckButton = $VBoxContainer/HBoxContainer2/AutoAcceptButton


# Called when the node enters the scene tree for the first time.
func _ready():
	dialogue_creation_manager.dialogues_ready_for_present_changed.connect(_on_dialogues_ready_for_present_changed)
	dialogue_creation_manager.new_dialogue_ready_for_present.connect(_on_new_dialogue_ready_for_present)
	dialogues_list.item_selected.connect(_on_dialogues_list_item_selected)


func _on_dialogues_ready_for_present_changed(new: Dictionary):
	dialogues_list.clear()
	var keys_arr = new.keys().duplicate()
	keys_arr.reverse()
	for id in keys_arr:
		var dialogue = new.get(id)
		var text = "{0} (id: {1}, lines: {2})".format([dialogue.topic, id, dialogue.replicas_count])
		var list_item_id = dialogues_list.add_item(text, null, true)
		dialogues_list.set_item_metadata(list_item_id, id)


func _on_new_dialogue_ready_for_present(id: int):
	if auto_accept_button.is_pressed():
		dialogue_creation_manager.approve_for_present(id)


func _on_dialogues_list_item_selected(item_id: int):
	var dialogue_id = dialogues_list.get_item_metadata(item_id)
	current_selected_dialogue = dialogue_id
	_update_dialogue_details()
	dialogue_details_container.show()


func _update_dialogue_details():
	var script: Array[VoicedReplica] = dialogue_creation_manager.get_complete_dialogue_script(current_selected_dialogue)
	script_text.text = _replicas_to_string(script)
	
	# update the voice lines container
	for child in voice_lines_container.get_children():
		child.queue_free()
	for i in range(script.size()):
		var replica = script[i]
		var line_container = voice_line_container.instantiate()
		
		# connect the play button
		var play_button: Button = line_container.get_node("HBoxContainer/PlayLineButton")
		play_button.pressed.connect(func(): _play_replica(i))
		
		# set the author label text
		var author_label: Label = line_container.get_node("HBoxContainer/AuthorLabel")
		author_label.text = Characters.character_to_string_capitalized(replica.author)
		
		voice_lines_container.add_child(line_container)


func _play_replica(replica_index: int):
	test_dialogue_player.stop()
	var script: Array[VoicedReplica] = dialogue_creation_manager.get_complete_dialogue_script(current_selected_dialogue)
	var voice_bytes = script[replica_index].voice_bytes
	test_dialogue_player.stream.data = voice_bytes
	test_dialogue_player.play()


func _replicas_to_string(replicas_arr: Array[VoicedReplica]) -> String:
	var res = ""
	for r in replicas_arr:
		res += Characters.character_to_string_capitalized(r.author)
		res += ": "
		res += r.text
		res += "\n"
	return res


func _on_remove_button_pressed():
	dialogue_creation_manager.remove_dialogue_present(current_selected_dialogue)
	current_selected_dialogue = -1
	dialogue_details_container.hide()


func _on_approve_button_pressed():
	dialogue_creation_manager.approve_for_present(current_selected_dialogue)
	current_selected_dialogue = -1
	dialogue_details_container.hide()
