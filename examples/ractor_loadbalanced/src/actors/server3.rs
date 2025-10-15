// Generated from ActorSimulation DSL
// Actor: server3

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Server3Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Server3Callbacks: Send + Sync {}

/// DefaultServer3Callbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultServer3Callbacks;

impl Server3Callbacks for DefaultServer3Callbacks {}

#[allow(dead_code)]
pub struct Server3State {
    callbacks: Box<dyn Server3Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Server3Message {
    Ping,
}

pub struct Server3;

impl Actor for Server3 {
    type Msg = Server3Message;
    type State = Server3State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Server3State {
            callbacks: Box::new(DefaultServer3Callbacks),
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
            Server3Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
