class_name DialogueSpeechGeneration
extends Node

signal enqueue_dialogue(id: int, dialogue: Array)

signal enqueued_dialogues_updated(new_queue: Dictionary)
signal current_generated_dialogue_changed(new_id: int)
signal current_generated_line_changed(new_line: String)

var tts_executor = RustTtsExecutor.new()

var enqueued_dialogues: Dictionary
var curr_dialogue_id = -1

@onready var dialogue_creation_manager: DialogueCreationManager = get_tree().get_first_node_in_group("g_dialogue_creation_man")


func _ready():
	add_child(tts_executor)
	
	# signal stuff
	enqueue_dialogue.connect(tts_executor.on_enqueue_dialogue)
	dialogue_creation_manager.dialogue_sent_to_tts.connect(_on_dialogue_sent_to_tts)
	tts_executor.started_generating_dialogue.connect(_on_started_generating_dialogue)
	tts_executor.started_generating_line.connect(_on_started_generating_line)
	tts_executor.done_generating_line.connect(_on_done_generating_line)
	tts_executor.done_generating_dialogue.connect(_on_done_generating_dialogue)
	tts_executor.error_generating_dialogue.connect(_on_error_generating_dialogue)


func get_connection_state() -> bool:
	return tts_executor.get_connection_state()


func reconnect():
	tts_executor.reconnect()


func _on_dialogue_sent_to_tts(id: int, dialogue: ParsedDialogue):
	enqueue_dialogue.emit(id, dialogue.to_array())
	
	enqueued_dialogues[id] = dialogue
	enqueued_dialogues_updated.emit(enqueued_dialogues)


func _on_started_generating_dialogue(id: int):
	current_generated_dialogue_changed.emit(id)
	dialogue_creation_manager.start_voicing_tts(id)
	curr_dialogue_id = id


func _on_started_generating_line(_id: int, line: String):
	current_generated_line_changed.emit(line)


func _on_done_generating_line(_id: int, _line: String, _bytes: PackedByteArray):
	current_generated_line_changed.emit("")


func _on_done_generating_dialogue(id: int, final_replicas_bytes: Array[PackedByteArray]):
	current_generated_dialogue_changed.emit(-1)
	dialogue_creation_manager.dialogue_voicing_complete.emit(id, final_replicas_bytes)
	
	curr_dialogue_id = -1
	
	enqueued_dialogues.erase(id)
	enqueued_dialogues_updated.emit(enqueued_dialogues)


func _on_error_generating_dialogue(id: int, error_str: String):
	if error_str != "canceled":
		push_error("Error while generating dialogue: ", error_str)
	
	current_generated_dialogue_changed.emit(-1)
	current_generated_line_changed.emit("")
	curr_dialogue_id = -1
	
	dialogue_creation_manager.error_generating_tts(id)


func cancel_generating():
	tts_executor.cancel_generating()
