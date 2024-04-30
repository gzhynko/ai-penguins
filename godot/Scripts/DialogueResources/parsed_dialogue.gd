class_name ParsedDialogue
extends Resource

const REPLICA_DELIMITER = ":"

@export var dialogue_topic: String
@export var raw_lines: Array[String]

@export var replicas_count: int
@export var replicas: Array[Replica]

@export var is_sent_to_tts: bool
@export var being_voiced: bool


func _init(topic: String = "", raw_lines_arr = [] as Array[String]):
	dialogue_topic = topic
	raw_lines = raw_lines_arr
	is_sent_to_tts = false
	being_voiced = false
	parse_raw_lines(raw_lines_arr)


func parse_raw_lines(lines: Array[String]):
	for line in lines:
		var line_components = line.split(REPLICA_DELIMITER)
		if line_components.size() != 2:
			continue
		
		var author = line_components[0]; var text = line_components[1]
		var possible_char = Characters.get_possible_character(author)
		if possible_char == Characters.Character.NONE:
			continue
		
		var trimmed_text = text.strip_edges().trim_prefix("\"").trim_suffix("\"")
		if trimmed_text.is_empty():
			continue
		
		var replica = Replica.new(possible_char, trimmed_text)
		replicas.push_back(replica)
	
	replicas_count = replicas.size()


func to_array() -> Array[Array]:
	var result: Array[Array] = []
	for replica in replicas:
		result.push_back([Characters.character_to_string(replica.author), replica.text])
	return result
