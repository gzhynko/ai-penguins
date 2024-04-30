class_name PromptCreationHelper
extends Node


static func generate_characters_from_topic_str(topic: String) -> Array[Characters.Character]:
	var prompt_characters = extract_characters_from_prompt(topic)
	var prompt_chars_count = prompt_characters.size()
	
	# To spice things up a bit, we add some random characters to the convo
	# If the prompt already mentions 3 or 4 characters, just return the prompt characters
	# Otherwise, add several new characters
	if prompt_chars_count >= 3:
		return prompt_characters
	
	var rng = RandomNumberGenerator.new()
	var target_char_count = rng.randi_range(2, 4)
	if target_char_count == prompt_chars_count:
		return prompt_characters
	
	# add the remaining characters until we reach the target char count
	for i in range(0, target_char_count - prompt_chars_count):
		var char_to_add = (rng.randi_range(0, 3)) as Characters.Character
		while prompt_characters.has(char_to_add):
			char_to_add = (rng.randi_range(0, 3)) as Characters.Character
		prompt_characters.push_back(char_to_add)
	
	return prompt_characters


static func extract_characters_from_prompt(prompt: String) -> Array[Characters.Character]:
	return Characters.get_characters_from_string(prompt)


static func character_array_to_string_array(char_arr: Array[Characters.Character]) -> Array[String]:
	var res: Array[String] = []
	for character in char_arr:
		res.push_back(Characters.character_to_string(character))
	return res
