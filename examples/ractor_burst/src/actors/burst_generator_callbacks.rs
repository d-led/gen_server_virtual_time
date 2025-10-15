// Generated from ActorSimulation DSL
// Default callback implementation for: burst_generator
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!

use super::burst_generator::BurstGeneratorCallbacks;

/// DefaultBurstGeneratorCallbacks provides default implementations
/// CUSTOMIZE THIS to add your own behavior!
pub struct DefaultBurstGeneratorCallbacks;

impl BurstGeneratorCallbacks for DefaultBurstGeneratorCallbacks {
    fn on_batch(&self) {
        // TODO: Implement custom behavior for batch
        println!("BurstGenerator: Sending batch message");
    }
}
