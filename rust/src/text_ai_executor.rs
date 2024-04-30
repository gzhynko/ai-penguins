use godot::prelude::*;
use crate::dialogue_instance::DialogueInstance;
use crate::local_llm_client::{LocalClientMessage, LocalLlmClient};

#[derive(GodotClass)]
#[class(base=Node)]
struct RustTextAiExecutor {
    llm_client: LocalLlmClient,
    dialogue_queue: Vec<DialogueInstance>,
    is_generating: bool,
    current_generated_lines: Vec<String>,
    current_dialogue_id: i32,
    refresh_gen_lines_counter: f32,

    base: Base<Node>
}

#[godot_api]
impl INode for RustTextAiExecutor {
    fn init(base: Base<Node>) -> Self {
        let llm_client = LocalLlmClient::new();

        Self {
            llm_client,
            dialogue_queue: Vec::new(),
            is_generating: false,
            current_generated_lines: Vec::new(),
            current_dialogue_id: -1,
            refresh_gen_lines_counter: 0.0,
            base,
        }
    }

    fn process(&mut self, delta: f64) {
        if let Ok(message) = self.llm_client.try_receive() {
            match message {
                LocalClientMessage::ReceivedGenerationDone(gen_res) => {
                    // print the last line..
                    if &gen_res.full_generated_lines != &self.current_generated_lines {
                        self.line_ready(&gen_res.full_generated_lines.clone().last().unwrap());
                    }

                    // .. and we are done generating!
                    self.dialogue_gen_done(&gen_res.full_generated_lines, &gen_res.create_inference_stats_array(self.current_dialogue_id + 1));

                    // reset generated lines array and current id
                    self.is_generating = false;
                    self.current_generated_lines = Vec::new();
                    self.current_dialogue_id = -1;
                },
                LocalClientMessage::ReceivedCurrentGeneratedLinesResponse(lines) => {
                    if lines != self.current_generated_lines && self.is_generating {
                        let difference: Vec<String> = lines.clone().into_iter().filter(|item| !self.current_generated_lines.contains(item)).collect();
                        self.current_generated_lines = lines;
                        for it in difference {
                            self.line_ready(&it);
                        }
                    }
                },
                _ => {
                    println!("unexpected message type received");
                }
            }
        }

        if self.is_generating && self.refresh_gen_lines_counter > 0.5 {
            self.refresh_gen_lines_counter = 0.0;
            self.llm_client.request_current_generated_lines();
        }
        self.refresh_gen_lines_counter += delta as f32;

        if self.llm_client.get_connection_state() && !self.is_generating {
            self.start_generation();
        }
    }

    fn ready(&mut self) {
        self.llm_client.run();
    }
}

#[godot_api]
impl RustTextAiExecutor {
    #[signal]
    fn conversation_line_ready(line_string: GString);
    #[signal]
    fn dialogue_done(id: i32, full_dialogue: Array<GString>, inference_stats: Array<f32>);
    #[signal]
    fn topic_start_execution(id: i32);

    #[func]
    fn on_enqueue_topic(&mut self, id: i32, topic: GString, characters: Array<GString>) {
        godot_print!("[rust] New topic enqueued: {}.", topic.to_string());
        self.dialogue_queue.push(DialogueInstance::from_godot_array(id, topic, characters));
    }

    #[func]
    fn on_remove_topic(&mut self, id: i32) {
        let mut to_remove: usize = 99999999;

        for i in 0..self.dialogue_queue.len() {
            if self.dialogue_queue[i].id == id {
                to_remove = i;
                break;
            }
        }

        if to_remove != 99999999 {
            self.dialogue_queue.remove(to_remove);
            godot_print!("[rust] Topic removed (id {}).", id);
        }
    }

    #[func]
    fn cancel_generating(&mut self) {
        self.llm_client.disconnect();
        self.llm_client.run();

        self.is_generating = false;
        self.current_generated_lines = Vec::new();
        self.current_dialogue_id = -1;
    }

    #[func]
    fn get_connection_state(&self) -> bool {
        self.llm_client.get_connection_state()
    }

    #[func]
    fn reconnect(&mut self) {
        self.llm_client.disconnect();
        self.llm_client = LocalLlmClient::new();
        self.llm_client.run();
    }

    fn line_ready(&mut self, line: &String) {
        self.base_mut().emit_signal("conversation_line_ready".into(), &[Variant::from(line.clone())]);
    }

    fn dialogue_gen_done(&mut self, full_dialogue: &Vec<String>, inference_stats: &Vec<f32>) {
        // create dialogue lines godot array
        let vec_godot_strs: Vec<GString> = full_dialogue.clone().iter().map(|str| GString::from(str)).collect();
        let mut dialogue_godot_array = Array::new();
        for str in vec_godot_strs {
            dialogue_godot_array.push(str);
        }

        // create inference stats godot array
        let mut infstats_godot_array = Array::<f32>::new();
        for val in inference_stats {
            infstats_godot_array.push(*val);
        }

        let id = self.current_dialogue_id;
        self.base_mut().emit_signal("dialogue_done".into(), &[Variant::from(id), Variant::from(dialogue_godot_array), Variant::from(infstats_godot_array)]);
    }

    fn start_generation(&mut self) {
        if self.dialogue_queue.is_empty() {
            return;
        }

        // start new dialogue gen
        self.is_generating = true;
        let next_dialogue = self.dialogue_queue.remove(0);
        // update current id
        self.current_dialogue_id = next_dialogue.id;
        // emit the signal
        self.base_mut().emit_signal("topic_start_execution".into(), &[Variant::from(next_dialogue.id)]);

        godot_print!("[rust] Executing topic: {}.", next_dialogue.topic);
        self.llm_client.request_prompt(next_dialogue.get_prompt_string());
    }
}


