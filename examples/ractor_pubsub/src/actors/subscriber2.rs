// Generated from ActorSimulation DSL
// Actor: subscriber2
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use super::subscriber2_callbacks::DefaultSubscriber2Callbacks;

/// Subscriber2Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Subscriber2Callbacks: Send + Sync {}


#[allow(dead_code)]
pub struct Subscriber2State {
    callbacks: Box<dyn Subscriber2Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Subscriber2Message {
    Ping,
}

pub struct Subscriber2;

impl Actor for Subscriber2 {
    type Msg = Subscriber2Message;
    type State = Subscriber2State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Subscriber2State {
            callbacks: Box::new(DefaultSubscriber2Callbacks),
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
            Subscriber2Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
