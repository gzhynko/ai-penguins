#[derive(Clone)]
pub(crate) enum DialogueCharacter {
    Kowalski,
    Rico,
    Private,
    Skipper,
}

impl DialogueCharacter {
    pub(crate) fn from_str(str: &String) -> Self {
        match str.to_lowercase().as_str() {
            "kowalski" => Self::Kowalski,
            "rico" => Self::Rico,
            "private" => Self::Private,
            "skipper" => Self::Skipper,
            _ => panic!("[DialogueCharacter] Unknown character string: {}", str),
        }
    }

    pub(crate) fn to_string(&self) -> String {
        match self {
            Self::Skipper => "Skipper",
            Self::Kowalski => "Kowalski",
            Self::Rico => "Rico",
            Self::Private => "Private",
        }
            .to_string()
    }
}


#[derive(Clone)]
pub(crate) struct DialogueCharacters {
    characters: Vec<DialogueCharacter>,
}

impl DialogueCharacters {
    pub(crate) fn from_character_vec(characters: Vec<DialogueCharacter>) -> Self {
        Self {
            characters,
        }
    }

    pub(crate) fn from_string_vec(characters: Vec<String>) -> Self {
        let character_vec = characters.iter().map(|str| DialogueCharacter::from_str(str)).collect();

        Self::from_character_vec(character_vec)
    }

    pub(crate) fn to_prompt_string(&self) -> String {
        let mut res = String::new();
        for i in 0..self.characters.len() {
            res += match self.characters[i] {
                DialogueCharacter::Kowalski => crate::constants::KOWALSKI_PROMPT_STRING,
                DialogueCharacter::Rico => crate::constants::RICO_PROMPT_STRING,
                DialogueCharacter::Private => crate::constants::PRIVATE_PROMPT_STRING,
                DialogueCharacter::Skipper => crate::constants::SKIPPER_PROMPT_STRING,
            };

            if i != self.characters.len() - 1 {
                res += ", "
            }
        }

        return res
    }
}
