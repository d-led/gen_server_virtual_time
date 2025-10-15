// Generated from ActorSimulation DSL
// Actor: server1

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Server1Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Server1Callbacks: Send + Sync {}

/// DefaultServer1Callbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultServer1Callbacks;

impl Server1Callbacks for DefaultServer1Callbacks {}

#[allow(dead_code)]
pub struct Server1State {
    callbacks: Box<dyn Server1Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Server1Message {
    Ping,
}

pub struct Server1;

impl Actor for Server1 {
    type Msg = Server1Message;
    type State = Server1State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Server1State {
            callbacks: Box::new(DefaultServer1Callbacks),
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
            Server1Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
