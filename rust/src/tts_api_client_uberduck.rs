#![allow(dead_code, unused)]

use std::sync::{Arc, Mutex};
use std::thread;
use fakeyou::FakeYouClient;
use reqwest::StatusCode;
use serde::Serialize;
use crate::dialogue_characters::DialogueCharacter;

const API_KEY: &str = "pub_knczopkohkogcyahxc";
const API_SECRET: &str = "pk_bdd864e2-da3f-4310-91fb-31c992122bf5";

const JEFF_BENNETT_UUID: &str = "eaeb4839-6efd-4e36-833d-459da57228a2"; // Kowalski
const TOM_MCGRATH_UUID: &str = "64d38ace-f62c-4912-943e-d73c179495a5"; // Skipper
const J_PATRICK_STUART_UUID: &str = "59304ca3-70ea-4702-9af7-0b33410cafb4"; // Private

#[derive(Default)]
struct LineGenerationStatus {
    pub(crate) is_done: bool,
    pub(crate) result_bytes: Option<bytes::Bytes>,
    pub(crate) error_text: Option<String>,
}

#[derive(Serialize)]
struct ApiSpeakRequest {
    speech: String,
    voicemodel_uuid: String,
}

pub(crate) struct TtsApiClient {
    status: Arc<Mutex<LineGenerationStatus>>,
    client: Arc<reqwest::blocking::Client>,
}

impl TtsApiClient {
    pub(crate) fn new() -> Self {
        let client = reqwest::blocking::Client::builder()
            .build();

        Self {
            status: Arc::new(Mutex::new(LineGenerationStatus::default())),
            client: Arc::new(client.unwrap()),
        }
    }

    pub(crate) fn generate_replica(&mut self, author: &DialogueCharacter, text: String) {
        let status = self.status.clone();
        let mut status_lock = status.lock().unwrap();
        status_lock.is_done = false; status_lock.result_bytes = None;

        let mut voice_uuid = "";
        match author {
            DialogueCharacter::Kowalski => voice_uuid = JEFF_BENNETT_UUID,
            DialogueCharacter::Skipper => voice_uuid = TOM_MCGRATH_UUID,
            DialogueCharacter::Private => voice_uuid = J_PATRICK_STUART_UUID,
            DialogueCharacter::Rico => {
                status_lock.is_done = true;
                status_lock.result_bytes = Some(bytes::Bytes::new());
                return;
            }
        }
        drop(status_lock);

        let client = self.client.clone();
        let request_body = ApiSpeakRequest {
            speech: text,
            voicemodel_uuid: voice_uuid.to_string(),
        };
        let body_json = serde_json::to_string(&request_body).unwrap();
        thread::spawn(move || {
            let response = client.post("https://api.uberduck.ai/speak-synchronous")
                .header("Content-Type", "application/json")
                .basic_auth(API_KEY, Some(API_SECRET))
                .body(body_json)
                .send()
                .unwrap();

            let mut status_lock = status.lock().unwrap();
            if response.status().as_u16() == 200 {
                let bytes = response.bytes().unwrap();
                status_lock.is_done = true;
                status_lock.result_bytes = Some(bytes);
                status_lock.error_text = None;
            } else {
                status_lock.is_done = true;
                status_lock.result_bytes = None;
                status_lock.error_text = Some(response.text().unwrap())
            }
        });
    }

    pub(crate) fn is_done(&self) -> bool {
        let status_lock = self.status.as_ref().lock().unwrap();
        status_lock.is_done
    }

    pub(crate) fn get_generated_bytes(&self) -> Result<Option<bytes::Bytes>, String> {
        let status_lock = self.status.as_ref().lock().unwrap();
        if status_lock.error_text.is_some() {
            Err(status_lock.error_text.clone().unwrap())
        } else {
            Ok(status_lock.result_bytes.clone())
        }
    }
}
