use godot::prelude::*;
use crate::dialogue_characters::{DialogueCharacters};

#[derive(Clone)]
pub(crate) struct DialogueInstance {
    pub(crate) id: i32,
    pub(crate) topic: String,
    characters: DialogueCharacters,
}

impl DialogueInstance {
    pub(crate) fn from_godot_array(id: i32, topic: GString, characters_array: Array<GString>) -> Self {
        let mut str_vec = Vec::<String>::new();
        for i in 0..characters_array.len() {
            str_vec.push(characters_array.get(i).to_string());
        }

        Self {
            id,
            topic: topic.to_string(),
            characters: DialogueCharacters::from_string_vec(str_vec),
        }
    }

    pub(crate) fn get_prompt_string(&self) -> String {
        let topic = &self.topic;
        let chars_string = self.characters.to_prompt_string();

        format!("### Instruction: \
Write a conversation between characters of Penguins of Madagascar. \
You can only use these characters: {chars_string}. The penguins live in the Central Park Zoo in New York. \
Write more than 5 lines of dialogue. \
Topic: {topic}. \
### Response:")
    }
}
