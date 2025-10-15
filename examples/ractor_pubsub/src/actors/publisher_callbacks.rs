// Generated from ActorSimulation DSL
// Default callback implementation for: publisher
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!

use super::publisher::PublisherCallbacks;

/// DefaultPublisherCallbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultPublisherCallbacks;

impl PublisherCallbacks for DefaultPublisherCallbacks {
    fn on_event(&self) {
        // TODO: Implement custom behavior for event
        println!("Publisher: Sending event message");
    }
}
