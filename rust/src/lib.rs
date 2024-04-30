mod text_ai_executor;
mod dialogue_instance;
mod dialogue_characters;
mod constants;
mod local_llm_client;
mod tts_executor;
mod parsed_dialogue_instance;
mod tts_api_client;
mod tts_api_client_uberduck;
use godot::prelude::*;

struct Main;

#[gdextension]
unsafe impl ExtensionLibrary for Main {}
