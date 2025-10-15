// Generated from ActorSimulation DSL
// Actor: stage3
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use super::stage3_callbacks::DefaultStage3Callbacks;

/// Stage3Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Stage3Callbacks: Send + Sync {}


#[allow(dead_code)]
pub struct Stage3State {
    callbacks: Box<dyn Stage3Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Stage3Message {
    Ping,
}

pub struct Stage3;

impl Actor for Stage3 {
    type Msg = Stage3Message;
    type State = Stage3State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Stage3State {
            callbacks: Box::new(DefaultStage3Callbacks),
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
            Stage3Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
