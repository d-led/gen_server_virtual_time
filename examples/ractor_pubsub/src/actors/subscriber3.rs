// Generated from ActorSimulation DSL
// Actor: subscriber3
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Subscriber3Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Subscriber3Callbacks: Send + Sync {}


#[allow(dead_code)]
pub struct Subscriber3State {
    callbacks: Box<dyn Subscriber3Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Subscriber3Message {
    Ping,
}

pub struct Subscriber3;

impl Actor for Subscriber3 {
    type Msg = Subscriber3Message;
    type State = Subscriber3State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Subscriber3State {
            callbacks: Box::new(DefaultSubscriber3Callbacks),
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
            Subscriber3Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
