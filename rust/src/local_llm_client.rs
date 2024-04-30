use std::sync::mpsc::{channel, Receiver, Sender};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use godot::log::godot_print;
use message_io::network::{NetEvent, Transport};
use message_io::node;
use rust_llm_server_common::{GenerationResults, Message};
use std::thread;

pub(crate) enum LocalClientMessage {
    // send
    SendGeneratePrompt(String),
    SendRequestCurrentGeneratedLines,
    // receive
    ReceivedGenerationDone(GenerationResults),
    ReceivedCurrentGeneratedLinesResponse(Vec<String>),
    // local
    Disconnect,
}

pub(crate) struct LocalLlmClient {
    connected: Arc<AtomicBool>,
    thread_tx: Option<Sender<LocalClientMessage>>,
    local_rx: Option<Receiver<LocalClientMessage>>,
}

impl LocalLlmClient {
    pub(crate) fn new() -> Self {
        Self {
            connected: Arc::new(AtomicBool::new(false)),
            thread_tx: None,
            local_rx: None,
        }
    }

    pub(crate) fn run(&mut self) {
        let (local_tx, local_rx) = channel::<LocalClientMessage>();
        let (thread_tx, thread_rx) = channel::<LocalClientMessage>();
        self.local_rx = Some(local_rx);
        self.thread_tx = Some(thread_tx);

        let (handler, listener) = node::split::<()>();

        let server_addr = "127.0.0.1:5341";
        let (server_endpoint, _) = handler.network().connect(Transport::FramedTcp, server_addr).unwrap();

        let handler_sender_loop = handler.clone();
        thread::spawn(move || {
            loop {
                let block = thread_rx.recv();
                if let Ok(client_msg) = block {
                    match client_msg {
                        LocalClientMessage::SendGeneratePrompt(prompt) => {
                            let message = Message::GeneratePrompt(prompt);
                            let output_data = bincode::serialize(&message);
                            if let Ok(output_data_2) = output_data {
                                handler_sender_loop.network().send(server_endpoint, &output_data_2);
                            }
                        },
                        LocalClientMessage::SendRequestCurrentGeneratedLines => {
                            let message = Message::RequestCurrentGeneratedLines;
                            let output_data = bincode::serialize(&message);
                            if let Ok(output_data_2) = output_data {
                                handler_sender_loop.network().send(server_endpoint, &output_data_2);
                            }
                        },
                        LocalClientMessage::Disconnect => {
                            handler_sender_loop.stop();
                        },
                        _ => {}
                    }
                }
            }
        });

        let handler_listener_loop = handler.clone();
        let connected_clone = self.connected.clone();
        thread::spawn(move || {
            listener.for_each(move |event| match event.network() {
                NetEvent::Connected(_, established) => {
                    if established {
                        godot_print!("[rust] llm client connected to server");
                        connected_clone.store(true, Ordering::Relaxed);
                    } else {
                        godot_print!("[rust] llm client failed to connect to server");
                        connected_clone.store(false, Ordering::Relaxed);
                    }
                }
                NetEvent::Message(_, data) => {
                    let message: Message = bincode::deserialize(&data).unwrap();
                    match message {
                        Message::GenerationDone(gen_res) => {
                            local_tx.send(LocalClientMessage::ReceivedGenerationDone(gen_res)).unwrap();
                        },
                        Message::CurrentGeneratedLinesResponse(lines) => {
                            local_tx.send(LocalClientMessage::ReceivedCurrentGeneratedLinesResponse(lines)).unwrap();
                        },
                        _ => {
                            godot_print!("[rust] unexpected message type received");
                        },
                    }
                }
                NetEvent::Disconnected(_) => {
                    godot_print!("[rust] llm client disconnected from server");
                    connected_clone.store(false, Ordering::Relaxed);
                    handler_listener_loop.stop();
                }
                _ => {}
            });
        });
    }

    pub(crate) fn get_connection_state(&self) -> bool {
        self.connected.load(Ordering::Relaxed)
    }

    pub(crate) fn disconnect(&mut self) {
        self.thread_tx.as_ref().unwrap().send(LocalClientMessage::Disconnect).unwrap();
    }

    pub(crate) fn request_prompt(&self, prompt: String) {
        if self.thread_tx.is_none() {
            println!("run 'run()' first");
            return;
        }

        self.thread_tx.as_ref().unwrap().send(LocalClientMessage::SendGeneratePrompt(prompt)).unwrap();
    }

    pub(crate) fn request_current_generated_lines(&self) {
        if self.thread_tx.is_none() {
            println!("run 'run()' first");
            return;
        }

        self.thread_tx.as_ref().unwrap().send(LocalClientMessage::SendRequestCurrentGeneratedLines).unwrap();
    }

    pub(crate) fn try_receive(&self) -> Result<LocalClientMessage, std::sync::mpsc::TryRecvError> {
        if self.thread_tx.is_none() {
            println!("run 'run()' first");
            return Err(std::sync::mpsc::TryRecvError::Empty);
        }

        self.local_rx.as_ref().unwrap().try_recv()
    }
}
