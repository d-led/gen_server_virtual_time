// Generated from ActorSimulation DSL
// Default callback implementation for: source
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!

use super::source::SourceCallbacks;

/// DefaultSourceCallbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultSourceCallbacks;

impl SourceCallbacks for DefaultSourceCallbacks {
    fn on_data(&self) {
        // TODO: Implement custom behavior for data
        println!("Source: Sending data message");
    }
}
