// Generated from ActorSimulation DSL
// Actor: sink

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// SinkCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait SinkCallbacks: Send + Sync {}

/// DefaultSinkCallbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultSinkCallbacks;

impl SinkCallbacks for DefaultSinkCallbacks {}

#[allow(dead_code)]
pub struct SinkState {
    callbacks: Box<dyn SinkCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum SinkMessage {
    Ping,
}

pub struct Sink;

impl Actor for Sink {
    type Msg = SinkMessage;
    type State = SinkState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = SinkState {
            callbacks: Box::new(DefaultSinkCallbacks),
            send_count: 0,
        };

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
            SinkMessage::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
