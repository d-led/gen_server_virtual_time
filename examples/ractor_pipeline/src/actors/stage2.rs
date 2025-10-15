// Generated from ActorSimulation DSL
// Actor: stage2

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Stage2Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Stage2Callbacks: Send + Sync {}

/// DefaultStage2Callbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultStage2Callbacks;

impl Stage2Callbacks for DefaultStage2Callbacks {}

#[allow(dead_code)]
pub struct Stage2State {
    callbacks: Box<dyn Stage2Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Stage2Message {
    Ping,
}

pub struct Stage2;

impl Actor for Stage2 {
    type Msg = Stage2Message;
    type State = Stage2State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Stage2State {
            callbacks: Box::new(DefaultStage2Callbacks),
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
            Stage2Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
