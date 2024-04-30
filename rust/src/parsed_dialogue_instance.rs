use godot::prelude::{Array, VariantArray};
use crate::dialogue_characters::DialogueCharacter;

#[derive(Clone)]
pub(crate) struct ParsedDialogueReplica {
    pub(crate) author: DialogueCharacter,
    pub(crate) text: String,
}

impl ParsedDialogueReplica {
    pub(crate) fn to_readable_string(&self) -> String {
        format!("{}: {}", self.author.to_string(), self.text)
    }
}

#[derive(Clone)]
pub(crate) struct ParsedDialogueInstance {
    pub(crate) id: i32,
    replicas: Vec<ParsedDialogueReplica>,
}

impl ParsedDialogueInstance {
    pub(crate) fn from_godot_array(id: i32, replicas_array: Array<VariantArray>) -> Self {
        let mut replicas = Vec::<ParsedDialogueReplica>::new();
        for replica in replicas_array.iter_shared() {
            let author_string = replica.get(0).to_string();
            let author = DialogueCharacter::from_str(&author_string);
            let text = replica.get(1).to_string();
            replicas.push(ParsedDialogueReplica {
                author,
                text,
            })
        }

        Self {
            id,
            replicas,
        }
    }

    pub(crate) fn is_empty(&self) -> bool {
        self.replicas.is_empty()
    }

    pub(crate) fn get_replica_at_id(&self, id: i32) -> &ParsedDialogueReplica {
        &self.replicas[id as usize]
    }

    pub(crate) fn get_next_replica_id(&self, current_id: i32) -> Option<i32> {
        if current_id + 1 >= self.replicas.len() as i32 {
            None
        } else {
            Some(current_id + 1)
        }
    }
}
