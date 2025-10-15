// Generated from ActorSimulation DSL
// Actor: publisher
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use std::time::Duration;
use tokio::time::interval;

/// PublisherCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait PublisherCallbacks: Send + Sync {
    fn on_event(&self);
}


#[allow(dead_code)]
pub struct PublisherState {
    callbacks: Box<dyn PublisherCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum PublisherMessage {
    Event,
}

pub struct Publisher;

impl Actor for Publisher {
    type Msg = PublisherMessage;
    type State = PublisherState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = PublisherState {
            callbacks: Box::new(DefaultPublisherCallbacks),
            send_count: 0,
        };

        // Spawn periodic timer
        let actor_ref = myself.clone();
        tokio::spawn(async move {
            let mut interval = interval(Duration::from_millis(100));
            loop {
                interval.tick().await;
                let _ = actor_ref.send_message(Self::Msg::Event);
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
            PublisherMessage::Event => {
                state.callbacks.on_event();
                state.send_count += 1;
                // Note: To send to other actors, you would need their ActorRef.
                // Add target ActorRefs to the state in your custom implementation.
            }
        }
        Ok(())
    }
}
