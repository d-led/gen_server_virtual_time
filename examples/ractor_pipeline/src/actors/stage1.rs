// Generated from ActorSimulation DSL
// Actor: stage1

use ractor::{Actor, ActorProcessingErr, ActorRef};

/// Stage1Callbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait Stage1Callbacks: Send + Sync {}

/// DefaultStage1Callbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultStage1Callbacks;

impl Stage1Callbacks for DefaultStage1Callbacks {}

#[allow(dead_code)]
pub struct Stage1State {
    callbacks: Box<dyn Stage1Callbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum Stage1Message {
    Ping,
}

pub struct Stage1;

impl Actor for Stage1 {
    type Msg = Stage1Message;
    type State = Stage1State;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = Stage1State {
            callbacks: Box::new(DefaultStage1Callbacks),
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
            Stage1Message::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
