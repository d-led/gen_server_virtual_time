// Generated from ActorSimulation DSL
// Actor: processor
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// ProcessorCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait ProcessorCallbacks: Send + Sync {}


#[allow(dead_code)]
pub struct ProcessorState {
    callbacks: Box<dyn ProcessorCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum ProcessorMessage {
    Ping,
}

pub struct Processor;

impl Actor for Processor {
    type Msg = ProcessorMessage;
    type State = ProcessorState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = ProcessorState {
            callbacks: Box::new(DefaultProcessorCallbacks),
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
            ProcessorMessage::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
