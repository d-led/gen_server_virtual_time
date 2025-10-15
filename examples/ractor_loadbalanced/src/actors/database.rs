// Generated from ActorSimulation DSL
// Actor: database
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use super::database_callbacks::DefaultDatabaseCallbacks;

/// DatabaseCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait DatabaseCallbacks: Send + Sync {}


#[allow(dead_code)]
pub struct DatabaseState {
    callbacks: Box<dyn DatabaseCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum DatabaseMessage {
    Ping,
}

pub struct Database;

impl Actor for Database {
    type Msg = DatabaseMessage;
    type State = DatabaseState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = DatabaseState {
            callbacks: Box::new(DefaultDatabaseCallbacks),
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
            DatabaseMessage::Ping => {
                // Default message handler
            }
        }
        Ok(())
    }
}
