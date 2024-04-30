class_name DialogueCreationManager
extends Node

signal new_dialogue_ready_for_tts(id: int)
signal new_dialogue_ready_for_present(id: int)

signal dialogue_ready_for_tts(id: int, dialogue: ParsedDialogue)
signal dialogues_ready_for_tts_changed(new: Dictionary)
signal dialogue_sent_to_tts(id: int, dialogue: ParsedDialogue)

signal dialogue_voicing_complete(id: int, voice_data: Array[PackedByteArray])
signal dialogues_ready_for_present_changed(new: Dictionary)

var dialogues_ready_for_tts: Dictionary # id : ParsedDialogue
var dialogues_ready_for_present: Dictionary # id : CompleteDialogue

@onready var presentation_manager: PresentationManager = get_tree().get_first_node_in_group("g_presentation_man")


func _ready():
	dialogue_ready_for_tts.connect(_on_dialogue_ready_for_tts)
	dialogue_voicing_complete.connect(_on_dialogue_voicing_complete)


func parse_loaded_ready_for_tts_dialogues(d: Dictionary):
	dialogues_ready_for_tts = d
	
	# approve the dialogue that's already being processed by tts first
	for id in dialogues_ready_for_tts.keys():
		if dialogues_ready_for_tts.get(id).being_voiced:
			approve_for_tts(id)
	
	# approve the rest of the dialogues that were already sent to tts
	for id in dialogues_ready_for_tts.keys():
		if dialogues_ready_for_tts.get(id).is_sent_to_tts and not dialogues_ready_for_tts.get(id).being_voiced:
			approve_for_tts(id)
	
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)


func parse_loaded_ready_for_present_dialogues(d: Dictionary):
	dialogues_ready_for_present = d
	dialogues_ready_for_present_changed.emit(dialogues_ready_for_present)


func _on_dialogue_ready_for_tts(id: int, dialogue: ParsedDialogue):
	dialogues_ready_for_tts[id] = dialogue
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)
	
	new_dialogue_ready_for_tts.emit(id)


func _on_dialogue_voicing_complete(id: int, voice_data: Array[PackedByteArray]):
	var complete_dialogue = CompleteDialogue.from_voice_data(dialogues_ready_for_tts.get(id), voice_data)
	
	dialogues_ready_for_tts.erase(id)
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)
	
	dialogues_ready_for_present[id] = complete_dialogue
	dialogues_ready_for_present_changed.emit(dialogues_ready_for_present)
	
	new_dialogue_ready_for_present.emit(id)


func remove_dialogue_tts(id: int):
	dialogues_ready_for_tts.erase(id)
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)


func remove_dialogue_present(id: int):
	dialogues_ready_for_present.erase(id)
	dialogues_ready_for_present_changed.emit(dialogues_ready_for_present)


func approve_for_tts(id: int):
	var dialogue = dialogues_ready_for_tts.get(id)
	if dialogue.replicas.is_empty():
		print("cannot approve an empty dialogue")
		return
	
	dialogue.is_sent_to_tts = true
	dialogue_sent_to_tts.emit(id, dialogue)
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)


func approve_for_present(id: int):
	presentation_manager.enqueue_for_present.emit(id, dialogues_ready_for_present.get(id))
	dialogues_ready_for_present.erase(id)
	dialogues_ready_for_present_changed.emit(dialogues_ready_for_present)


func error_generating_tts(id: int):
	dialogues_ready_for_tts.get(id).is_sent_to_tts = false
	dialogues_ready_for_tts.get(id).being_voiced = false
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)


func start_voicing_tts(id: int):
	dialogues_ready_for_tts.get(id).being_voiced = true
	dialogues_ready_for_tts_changed.emit(dialogues_ready_for_tts)


func get_tts_dialogue_script(id: int) -> Array[Replica]:
	return dialogues_ready_for_tts.get(id).replicas


func get_tts_dialogue_raw_lines(id: int) -> Array[String]:
	return dialogues_ready_for_tts.get(id).raw_lines


func is_tts_dialogue_in_queue(id: int) -> bool:
	return dialogues_ready_for_tts.get(id).is_sent_to_tts


func get_complete_dialogue_script(id: int) -> Array[VoicedReplica]:
	return dialogues_ready_for_present.get(id).replicas
