class_name SaveLoadManager
extends Node

const TEXT_GEN_QUEUE_PATH = "user://saved-data/text_gen_queue.tres"
const PRESENT_QUEUE_PATH = "user://saved-data/present_queue.tres"
const READY_FOR_TTS_PATH = "user://saved-data/ready_for_tts.tres"
const READY_FOR_PRESENT_PATH = "user://saved-data/ready_for_present.tres"

@onready var dialogue_text_gen: DialogueTextGeneration = get_tree().get_first_node_in_group("g_dialogue_text_gen")
@onready var dialogue_speech_gen: DialogueSpeechGeneration = get_tree().get_first_node_in_group("g_dialogue_speech_gen")
@onready var dialogue_creation_man: DialogueCreationManager = get_tree().get_first_node_in_group("g_dialogue_creation_man")
@onready var presentation_man: PresentationManager = get_tree().get_first_node_in_group("g_presentation_man")


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(0.1).timeout
	
	# load
	_load_present_queue()
	_load_text_gen_queue()
	_load_ready_for_present()
	_load_ready_for_tts()

	# save
	dialogue_text_gen.enqueued_topics_updated.connect(_on_text_gen_enqueued_topics_updated)
	dialogue_text_gen.current_topic_updated.connect(_on_text_gen_current_topic_updated)
	
	presentation_man.present_queue_updated.connect(_on_presentation_man_present_queue_updated)
	
	dialogue_creation_man.dialogues_ready_for_tts_changed.connect(_on_dialogue_creation_man_dialogues_ready_for_tts_changed)
	dialogue_creation_man.dialogues_ready_for_present_changed.connect(_on_dialogue_creation_man_dialogues_ready_for_present_changed)


# LOADING-RELATED STUFF

func _load_text_gen_queue():
	var path = TEXT_GEN_QUEUE_PATH
	if not ResourceLoader.exists(path):
		return
	var data = load(path) as TextGenQueueResource
	
	if data.has_current:
		dialogue_text_gen.add_topic_with_id(data.current_id, data.current)
	
	for id in data.queue.keys():
		dialogue_text_gen.add_topic_with_id(id, data.queue.get(id))


func _load_present_queue():
	var path = PRESENT_QUEUE_PATH
	if not ResourceLoader.exists(path):
		return
	var data = load(path) as PresentQueueResource
	
	for id in data.queue.keys():
		presentation_man.enqueue_for_present.emit(id, data.queue.get(id))


func _load_ready_for_tts():
	var path = READY_FOR_TTS_PATH
	if not ResourceLoader.exists(path):
		return
	var data = load(path) as ReadyForTtsResource
	
	dialogue_creation_man.parse_loaded_ready_for_tts_dialogues(data.dialogues)


func _load_ready_for_present():
	var path = READY_FOR_PRESENT_PATH
	if not ResourceLoader.exists(path):
		return
	var data = load(path) as ReadyForPresentResource
	
	dialogue_creation_man.parse_loaded_ready_for_present_dialogues(data.dialogues)

# SAVING-RELATED STUFF

func _save_text_gen_queue():
	var path = TEXT_GEN_QUEUE_PATH
	
	var data = TextGenQueueResource.new()
	data.has_current = not dialogue_text_gen.current_topic.is_empty()
	data.current = dialogue_text_gen.current_topic
	data.current_id = dialogue_text_gen.current_topic_id
	data.queue = dialogue_text_gen.enqueued_topics
	
	ResourceSaver.save(data, path)


func _save_present_queue():
	var path = PRESENT_QUEUE_PATH
	
	var data = PresentQueueResource.new()
	data.queue = presentation_man.present_queue
	
	ResourceSaver.save(data, path)


func _save_ready_for_tts():
	var path = READY_FOR_TTS_PATH
	
	var data = ReadyForTtsResource.new()
	data.dialogues = dialogue_creation_man.dialogues_ready_for_tts
	
	ResourceSaver.save(data, path)


func _save_ready_for_present():
	var path = READY_FOR_PRESENT_PATH
	
	var data = ReadyForPresentResource.new()
	data.dialogues = dialogue_creation_man.dialogues_ready_for_present
	
	ResourceSaver.save(data, path)

# SIGNAL STUFF

func _on_text_gen_enqueued_topics_updated(_a):
	_save_text_gen_queue()
func _on_text_gen_current_topic_updated(_i, _a):
	_save_text_gen_queue()

func _on_presentation_man_present_queue_updated(_a):
	_save_present_queue()

func _on_dialogue_creation_man_dialogues_ready_for_tts_changed(_a):
	_save_ready_for_tts()
func _on_dialogue_creation_man_dialogues_ready_for_present_changed(_a):
	_save_ready_for_present()
