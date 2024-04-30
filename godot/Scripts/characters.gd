class_name Characters
extends Node

enum Character {
	KOWALSKI,
	RICO,
	SKIPPER,
	PRIVATE,
	NONE,
}


static func get_characters_from_string(chars_str: String) -> Array[Character]:
	var res: Array[Character] = []
	
	for word in chars_str.split(" "):
		var possible_char = get_possible_character(word)
		if possible_char != Character.NONE and not res.has(possible_char):
			res.push_back(possible_char)
	
	return res


static func get_possible_character(name_string: String):
	var similarity_threshold = 0.5
	var possible_chars = [Character.KOWALSKI, Character.RICO, Character.SKIPPER, Character.PRIVATE]
	
	var closest_similarity_val = 0.0
	var closest_char = Character.NONE
	for character in possible_chars:
		var char_str = character_to_string(character)
		
		# if contains the char string - immidiately choose this char
		if name_string.to_lower().contains(char_str):
			closest_char = character
			break
		
		# if not, compare the similarity values
		var similarity = name_string.to_lower().similarity(char_str)
		if similarity > similarity_threshold and similarity > closest_similarity_val:
			closest_similarity_val = similarity
			closest_char = character
	
	return closest_char


static func character_to_string_capitalized(character: Character) -> String:
	match character:
		Character.KOWALSKI:
			return "Kowalski"
		Character.RICO:
			return "Rico"
		Character.SKIPPER:
			return "Skipper"
		Character.PRIVATE:
			return "Private"
		_:
			push_warning("Encountered an unknown character: ", character)
			return ""


static func character_to_string(character: Character) -> String:
	return character_to_string_capitalized(character).to_lower()
