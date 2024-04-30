class_name DialogueTextGeneration
extends Node

# (rust)
signal enqueue_topic(topic: String, characters: Array[String])
signal remove_topic(id: int)

signal enqueued_topics_updated(new_queue: Dictionary)
signal current_topic_updated(id: int, new_topic: String)

signal current_generated_lines_updated(new_arr: Array[String])

var text_ai_executor = RustTextAiExecutor.new()

var dialogue_id_counter: int
var enqueued_topics: Dictionary

var current_topic: String
var current_topic_id: int
var current_generated_lines: Array[String]

@onready var dialogue_creation_manager: DialogueCreationManager = get_tree().get_first_node_in_group("g_dialogue_creation_man")


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(text_ai_executor)
	enqueued_topics = {}
	
	# connect signals
	enqueue_topic.connect(text_ai_executor.on_enqueue_topic)
	remove_topic.connect(text_ai_executor.on_remove_topic)
	text_ai_executor.topic_start_execution.connect(_on_topic_start_execution)
	text_ai_executor.conversation_line_ready.connect(_on_conversation_line_ready)
	text_ai_executor.dialogue_done.connect(_on_dialogue_done)


func get_connection_state() -> bool:
	return text_ai_executor.get_connection_state()


func reconnect():
	text_ai_executor.reconnect()


func cancel_generating():
	text_ai_executor.cancel_generating()
	
	add_topic_with_id(current_topic_id, current_topic)


func _on_conversation_line_ready(line_str: String):
	current_generated_lines.push_back(line_str)
	current_generated_lines_updated.emit(current_generated_lines)


func _on_topic_start_execution(id: int):
	current_topic = enqueued_topics[id]
	current_topic_id = id
	enqueued_topics.erase(id)
	
	current_topic_updated.emit(id, current_topic)
	enqueued_topics_updated.emit(enqueued_topics)


func _on_dialogue_done(id: int, _full_script: Array[String], inference_stats: Array[float]):
	_parse_and_send_dialogue(id)
	
	ConsoleWindowManager.received_inference_stats.emit(inference_stats)


func _parse_and_send_dialogue(id: int):
	var parsed = ParsedDialogue.new(current_topic, current_generated_lines)
	dialogue_creation_manager.dialogue_ready_for_tts.emit(id, parsed)
	
	current_topic = ""
	current_topic_id = -1
	current_generated_lines = []
	
	current_topic_updated.emit(-1, "")
	current_generated_lines_updated.emit([] as Array[String])


func add_new_topic(topic: String) -> Array:
	var id = dialogue_id_counter

	var characters_string = add_topic_with_id(id, topic)
	dialogue_id_counter += 1
	
	return [id, characters_string]


func add_topic_with_id(id: int, topic: String) -> Array[String]:
	var characters: Array[Characters.Character] = PromptCreationHelper.generate_characters_from_topic_str(topic)
	
	var characters_string: Array[String] = PromptCreationHelper.character_array_to_string_array(characters)
	enqueue_topic.emit(id, topic, characters_string)
	
	enqueued_topics[id] = topic
	enqueued_topics_updated.emit(enqueued_topics)
	
	return characters_string


func remove_topic_id(id: int):
	remove_topic.emit(id)
	
	enqueued_topics.erase(id)
	enqueued_topics_updated.emit(enqueued_topics)

