class_name CompleteDialogue
extends Resource

@export var topic: String
@export var participants: Array[Characters.Character]
@export var replicas_count: int
@export var replicas: Array[VoicedReplica]


static func from_voice_data(parsed_dialogue: ParsedDialogue, voice_data: Array[PackedByteArray]) -> CompleteDialogue:
	var complete = CompleteDialogue.new()
	complete.topic = parsed_dialogue.dialogue_topic
	complete.replicas_count = parsed_dialogue.replicas_count
	for i in range(parsed_dialogue.replicas.size()):
		var replica = parsed_dialogue.replicas[i]
		var author = replica.author
		var text = replica.text
		
		if not complete.participants.has(author):
			complete.participants.push_back(author)
		var voiced_replica = VoicedReplica.new(author, text, voice_data[i])
		
		complete.replicas.push_back(voiced_replica)
	
	return complete


func get_next_line_n(current: int) -> int:
	if current + 1 >= replicas_count:
		return -1
	else:
		return current + 1
