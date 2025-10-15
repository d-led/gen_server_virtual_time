// Generated from ActorSimulation DSL
// Main entry point for burst_actors

use burst_actors::actors::burst_generator::BurstGenerator;
use burst_actors::actors::processor::Processor;
use ractor::Actor;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting actor system...");

    // Spawn all actors
    let (_burst_generator_ref, _burst_generator_handle) =
        BurstGenerator::spawn(None, BurstGenerator, ()).await?;

    let (_processor_ref, _processor_handle) = Processor::spawn(None, Processor, ()).await?;

    println!("Actor system started. Press Ctrl+C to exit.");

    // Keep running
    tokio::signal::ctrl_c().await?;
    println!("Shutting down...");

    Ok(())
}
