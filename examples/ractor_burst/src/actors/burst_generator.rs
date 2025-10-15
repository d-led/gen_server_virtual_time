// Generated from ActorSimulation DSL
// Actor: burst_generator
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use std::time::Duration;
use tokio::time::interval;

/// BurstGeneratorCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait BurstGeneratorCallbacks: Send + Sync {
    fn on_batch(&self);
}


#[allow(dead_code)]
pub struct BurstGeneratorState {
    callbacks: Box<dyn BurstGeneratorCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum BurstGeneratorMessage {
    Batch,
}

pub struct BurstGenerator;

impl Actor for BurstGenerator {
    type Msg = BurstGeneratorMessage;
    type State = BurstGeneratorState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = BurstGeneratorState {
            callbacks: Box::new(DefaultBurstGeneratorCallbacks),
            send_count: 0,
        };

        // Spawn burst timer (10 msgs every 1000ms)
        let actor_ref = myself.clone();
        tokio::spawn(async move {
            let mut interval = interval(Duration::from_millis(1000));
            loop {
                interval.tick().await;
                for _ in 0..10 {
                    let _ = actor_ref.send_message(Self::Msg::Batch);
                }
            }
        });
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
            BurstGeneratorMessage::Batch => {
                state.callbacks.on_batch();
                state.send_count += 1;
                // Note: To send to other actors, you would need their ActorRef.
                // Add target ActorRefs to the state in your custom implementation.
            }
        }
        Ok(())
    }
}
