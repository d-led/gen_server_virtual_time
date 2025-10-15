// Generated from ActorSimulation DSL
// Actor: server2

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Server2Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Server2Callbacks: Send + Sync {}

/// DefaultServer2Callbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultServer2Callbacks;

impl Server2Callbacks for DefaultServer2Callbacks {}

#[allow(dead_code)]
pub struct Server2State {
    callbacks: Box<dyn Server2Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Server2Message {
    Ping,
}

pub struct Server2;

impl Actor for Server2 {
    type Msg = Server2Message;
    type State = Server2State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Server2State {
            callbacks: Box::new(DefaultServer2Callbacks),
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
            Server2Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
