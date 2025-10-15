// Generated from ActorSimulation DSL
// Main entry point for pubsub_actors

use pubsub_actors::actors::publisher::Publisher;
use pubsub_actors::actors::subscriber1::Subscriber1;
use pubsub_actors::actors::subscriber2::Subscriber2;
use pubsub_actors::actors::subscriber3::Subscriber3;
use ractor::Actor;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting actor system...");

    // Spawn all actors
    let (_publisher_ref, _publisher_handle) = Publisher::spawn(None, Publisher, ()).await?;
    let (_subscriber1_ref, _subscriber1_handle) =
        Subscriber1::spawn(None, Subscriber1, ()).await?;

    let (_subscriber2_ref, _subscriber2_handle) =
        Subscriber2::spawn(None, Subscriber2, ()).await?;

    let (_subscriber3_ref, _subscriber3_handle) =
        Subscriber3::spawn(None, Subscriber3, ()).await?;


    println!("Actor system started. Press Ctrl+C to exit.");

    // Keep running
    tokio::signal::ctrl_c().await?;
    println!("Shutting down...");

    Ok(())
}
