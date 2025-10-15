// Generated from ActorSimulation DSL
// Actor: load_balancer
// DO NOT EDIT - This file is auto-generated

use ractor::{Actor, ActorProcessingErr, ActorRef};
use std::time::Duration;
use tokio::time::interval;

/// LoadBalancerCallbacks defines the callback trait
/// Implement this trait to customize actor behavior
pub trait LoadBalancerCallbacks: Send + Sync {
    fn on_request(&self);
}


#[allow(dead_code)]
pub struct LoadBalancerState {
    callbacks: Box<dyn LoadBalancerCallbacks + Send + Sync>,
    send_count: usize,
}

#[derive(Debug, Clone)]
pub enum LoadBalancerMessage {
    Request,
}

pub struct LoadBalancer;

impl Actor for LoadBalancer {
    type Msg = LoadBalancerMessage;
    type State = LoadBalancerState;
    type Arguments = ();

    #[allow(unused_variables)]
    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        let state = LoadBalancerState {
            callbacks: Box::new(DefaultLoadBalancerCallbacks),
            send_count: 0,
        };

        // Spawn rate-based timer (100 msgs/sec)
        let actor_ref = myself.clone();
        tokio::spawn(async move {
            let mut interval = interval(Duration::from_millis(10));
            loop {
                interval.tick().await;
                let _ = actor_ref.send_message(Self::Msg::Request);
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
            LoadBalancerMessage::Request => {
                state.callbacks.on_request();
                state.send_count += 1;
                // Note: To send to other actors, you would need their ActorRef.
                // Add target ActorRefs to the state in your custom implementation.
            }
        }
        Ok(())
    }
}
