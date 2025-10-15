// Generated from ActorSimulation DSL
// Actor: subscriber1
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Subscriber1Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Subscriber1Callbacks: Send + Sync {}


#[allow(dead_code)]
pub struct Subscriber1State {
    callbacks: Box<dyn Subscriber1Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Subscriber1Message {
    Ping,
}

pub struct Subscriber1;

impl Actor for Subscriber1 {
    type Msg = Subscriber1Message;
    type State = Subscriber1State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Subscriber1State {
            callbacks: Box::new(DefaultSubscriber1Callbacks),
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
            Subscriber1Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
