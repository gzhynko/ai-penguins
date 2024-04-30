use std::sync::{Arc, Mutex};
use std::thread;
use fakeyou::{FakeYouClient};
use godot::log::godot_error;
use crate::dialogue_characters::DialogueCharacter;

const JEFF_BENNETT_TOKEN: &str = "TM:epatvrvfj312"; // Kowalski
const TOM_MCGRATH_TOKEN: &str = "TM:3d9bj6hwrkk1"; // Skipper
const J_PATRICK_STUART_TOKEN: &str = "TM:m0z4srq49f8d"; // Private

#[derive(Default)]
struct LineGenerationStatus {
    pub(crate) is_done: bool,
    pub(crate) result_bytes: Option<bytes::Bytes>,
    pub(crate) error_message: Option<String>,
}

pub(crate) struct TtsApiClient {
    status: Arc<Mutex<LineGenerationStatus>>,
    client: Option<Arc<FakeYouClient>>,
}

impl TtsApiClient {
    pub(crate) fn new() -> Self {
        if let Err(e) = dotenvy::dotenv() {
            godot_error!("[rust] Unable to load env vars: {e}");
        }

        Self {
            status: Arc::new(Mutex::new(LineGenerationStatus::default())),
            client: None,
        }
    }

    pub(crate) fn auth(&mut self) -> Result<(), fakeyou::Error> {
        let auth_res = fakeyou::authenticate(&dotenvy::var("FAKEYOU_USERNAME").unwrap(), &dotenvy::var("FAKEYOU_PASSWORD").unwrap());
        match auth_res {
            Ok(client) => {
                self.client = Some(Arc::new(client));
                Ok(())
            }
            Err(err) => {
                Err(err)
            }
        }
    }

    pub(crate) fn is_authenticated(&self) -> bool {
        self.client.is_some()
    }

    pub(crate) fn generate_replica(&mut self, author: &DialogueCharacter, text: String) {
        let status = self.status.clone();
        let mut status_lock = status.lock().unwrap();
        status_lock.is_done = false; status_lock.result_bytes = None;

        let voice_token;
        match author {
            DialogueCharacter::Kowalski => voice_token = JEFF_BENNETT_TOKEN,
            DialogueCharacter::Skipper => voice_token = TOM_MCGRATH_TOKEN,
            DialogueCharacter::Private => voice_token = J_PATRICK_STUART_TOKEN,
            DialogueCharacter::Rico => {
                status_lock.is_done = true;
                status_lock.result_bytes = Some(bytes::Bytes::new());
                return;
            }
        }

        if self.client.is_none() {
            status_lock.is_done = true;
            status_lock.result_bytes = None;
            status_lock.error_message = Some("Not authenticated.".to_string());
        }

        drop(status_lock);

        let client = self.client.as_ref().unwrap().clone();
        thread::spawn(move || {
            // this will block
            let generate_result = client.generate_bytes_from_token(&text, voice_token);

            let mut status_lock = status.lock().unwrap();
            match generate_result {
                Ok(bytes) => {
                    status_lock.is_done = true;
                    status_lock.result_bytes = Some(bytes);
                    status_lock.error_message = None;
                },
                Err(error) => {
                    status_lock.is_done = true;
                    status_lock.result_bytes = None;
                    status_lock.error_message = Some(error.to_string());
                },
            }
        });
    }

    pub(crate) fn is_done(&self) -> bool {
        let status_lock = self.status.as_ref().lock().unwrap();
        status_lock.is_done
    }

    pub(crate) fn get_generated_bytes(&self) -> Result<Option<bytes::Bytes>, String> {
        let status_lock = self.status.as_ref().lock().unwrap();
        if status_lock.error_message.is_some() {
            Err(status_lock.error_message.clone().unwrap())
        } else {
            Ok(status_lock.result_bytes.clone())
        }
    }
}
