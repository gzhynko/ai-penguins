use bytes::Bytes;
use godot::prelude::*;
use crate::parsed_dialogue_instance::ParsedDialogueInstance;
use crate::tts_api_client::TtsApiClient;

#[derive(GodotClass)]
#[class(base=Node)]
struct RustTtsExecutor {
    tts_client: TtsApiClient,

    is_generating_dialogue: bool,
    tts_dialogue_queue: Vec<ParsedDialogueInstance>,

    current_dialogue: Option<ParsedDialogueInstance>,
    current_generated_line_id: i32,
    current_generated_replicas_bytes: Vec<bytes::Bytes>,
    refresh_is_done_timer: f32,

    base: Base<Node>
}

#[godot_api]
impl INode for RustTtsExecutor {
    fn init(base: Base<Node>) -> Self {
        Self {
            tts_client: TtsApiClient::new(),

            is_generating_dialogue: false,
            tts_dialogue_queue: Vec::new(),

            current_dialogue: None,
            current_generated_line_id: 0,
            current_generated_replicas_bytes: Vec::new(),
            refresh_is_done_timer: 0.0,

            base,
        }
    }

    fn process(&mut self, delta: f64) {
        if !self.is_generating_dialogue && !self.tts_dialogue_queue.is_empty() {
            self.start_generating_dialogue();
            return;
        }

        if self.refresh_is_done_timer >= 0.1 {
            self.refresh_is_done_timer = 0.0;

            if self.is_generating_dialogue && self.tts_client.is_done() {
                let current_dialogue = self.current_dialogue.as_ref().unwrap();

                let result_bytes = self.tts_client.get_generated_bytes().clone();
                let bytes: Option<Bytes>;
                match result_bytes {
                    Ok(bytes_opt) => {
                        bytes = bytes_opt;
                    }
                    Err(err_str) => {
                        let curr_dialogue_id = current_dialogue.id;

                        self.base_mut().emit_signal("error_generating_dialogue".into(), &[Variant::from(curr_dialogue_id), Variant::from(err_str)]);
                        self.is_generating_dialogue = false;
                        self.current_dialogue = None;
                        return;
                    }
                }

                let bytes_res = bytes.unwrap();
                self.current_generated_replicas_bytes.push(bytes_res.clone());

                let curr_line_id = self.current_generated_line_id;
                let curr_dialogue_id = current_dialogue.id;
                let curr_replica_text = current_dialogue.get_replica_at_id(curr_line_id).text.clone();
                let packed_byte_array = PackedByteArray::from(bytes_res.as_ref());
                let next_dialogue_line_id = current_dialogue.get_next_replica_id(curr_line_id);
                self.base_mut().emit_signal("done_generating_line".into(), &[Variant::from(curr_dialogue_id), Variant::from(curr_replica_text), Variant::from(packed_byte_array)]);

                if next_dialogue_line_id.is_none() {
                    let mut final_array = Array::new();
                    for bytes in &self.current_generated_replicas_bytes {
                        let packed_byte_array = PackedByteArray::from(bytes.as_ref());
                        final_array.push(packed_byte_array)
                    }
                    self.is_generating_dialogue = false;
                    self.base_mut().emit_signal("done_generating_dialogue".into(), &[Variant::from(curr_dialogue_id), Variant::from(final_array)]);

                    return;
                }

                self.current_generated_line_id = next_dialogue_line_id.unwrap();
                self.start_generating_line();
            }
        }
        self.refresh_is_done_timer += delta as f32;
    }
}

#[godot_api]
impl RustTtsExecutor {
    #[signal]
    fn started_generating_dialogue(dialogue_id: i32);
    #[signal]
    fn started_generating_line(dialogue_id: i32, line: GString);
    #[signal]
    fn done_generating_line(dialogue_id: i32, line: GString, bytes: PackedByteArray);
    #[signal]
    fn done_generating_dialogue(dialogue_id: i32, final_replica_bytes: Array<PackedByteArray>);
    #[signal]
    fn error_generating_dialogue(dialogue_id: i32, error_text: GString);

    #[func]
    fn on_enqueue_dialogue(&mut self, id: i32, replicas_array: Array<VariantArray>) {
        self.tts_dialogue_queue.push(ParsedDialogueInstance::from_godot_array(id, replicas_array));
    }

    #[func]
    fn get_connection_state(&self) -> bool {
        self.tts_client.is_authenticated()
    }

    #[func]
    fn cancel_generating(&mut self) {
        if let Some(current_dialogue) = &self.current_dialogue.clone() {
            self.reconnect();

            self.base_mut().emit_signal("error_generating_dialogue".into(), &[Variant::from(current_dialogue.id), Variant::from("canceled")]);
            self.is_generating_dialogue = false;
            self.current_dialogue = None;
        }
    }

    #[func]
    fn reconnect(&mut self) {
        self.tts_client = TtsApiClient::new();
        let auth_res = self.tts_client.auth();
        if let Err(e) = auth_res {
            godot_error!("[rust] unable to authenticate TTS: {}", e.to_string());
            return;
        }
    }

    fn start_generating_dialogue(&mut self) {
        if self.tts_dialogue_queue.is_empty() {
            return;
        }
        if !self.tts_client.is_authenticated() {
            let auth_res = self.tts_client.auth();
            if let Err(e) = auth_res {
                godot_error!("[rust] unable to authenticate TTS: {}", e.to_string());
                return;
            }
        }

        let next = self.tts_dialogue_queue.remove(0);
        let id = next.id;
        if next.is_empty() {
            self.base_mut().emit_signal("error_generating_dialogue".into(), &[Variant::from(id), Variant::from("dialogue is empty")]);
            return;
        }
        self.is_generating_dialogue = true;

        self.current_dialogue = Some(next);
        self.current_generated_line_id = 0;
        self.current_generated_replicas_bytes = Vec::new();
        self.base_mut().emit_signal("started_generating_dialogue".into(), &[Variant::from(id)]);

        self.start_generating_line();
    }

    fn start_generating_line(&mut self) {
        if self.current_dialogue.is_none() {
            return;
        }
        let curr_dialogue = self.current_dialogue.as_ref().unwrap();
        let id = curr_dialogue.id;

        let line = curr_dialogue.get_replica_at_id(self.current_generated_line_id);
        let readable_str = line.to_readable_string();
        let text = line.text.clone();
        let author = line.author.clone();
        self.base_mut().emit_signal("started_generating_line".into(), &[Variant::from(id), Variant::from(readable_str)]);

        self.tts_client.generate_replica(&author, text.clone());
    }
}
