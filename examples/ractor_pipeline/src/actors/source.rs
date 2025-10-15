// Generated from ActorSimulation DSL
// Actor: source
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use std::time::Duration;
use tokio::time::interval;
use super::source_callbacks::DefaultSourceCallbacks;

/// SourceCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait SourceCallbacks: Send + Sync {
    fn on_data(&self);
}


#[allow(dead_code)]
pub struct SourceState {
    callbacks: Box<dyn SourceCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum SourceMessage {
    Data,
}

pub struct Source;

impl Actor for Source {
    type Msg = SourceMessage;
    type State = SourceState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = SourceState {
            callbacks: Box::new(DefaultSourceCallbacks),
            send_count: 0,
        };

        // Spawn rate-based timer (50 msgs/sec)
        let actor_ref = myself.clone();
        tokio::spawn(async move {
            let mut interval = interval(Duration::from_millis(20));
            loop {
                interval.tick().await;
                let _ = actor_ref.send_message(Self::Msg::Data);
            }
        });
        Ok(state)
    }

    #[allow(unused_variables)]
    async fn handle(
        &self,
        _myself: ActorRef<Self::Msg>,
        message: Self::Msg,
        state: &mut Self::State,
    ) -> Result<(), ActorProcessingErr> {
        match message {
            SourceMessage::Data => {
                state.callbacks.on_data();
                state.send_count += 1;
                // Note: To send to other actors, you would need their ActorRef.
                // Add target ActorRefs to the state in your custom implementation.
            }
        }
        Ok(())
    }
}
