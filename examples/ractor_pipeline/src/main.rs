// Generated from ActorSimulation DSL
// Main entry point for pipeline_actors

use pipeline_actors::actors::sink::Sink;
use pipeline_actors::actors::source::Source;
use pipeline_actors::actors::stage1::Stage1;
use pipeline_actors::actors::stage2::Stage2;
use pipeline_actors::actors::stage3::Stage3;
use ractor::Actor;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting actor system...");

    // Spawn all actors
    let (_sink_ref, _sink_handle) = Sink::spawn(None, Sink, ()).await?;
    let (_source_ref, _source_handle) = Source::spawn(None, Source, ()).await?;
    let (_stage1_ref, _stage1_handle) = Stage1::spawn(None, Stage1, ()).await?;
    let (_stage2_ref, _stage2_handle) = Stage2::spawn(None, Stage2, ()).await?;
    let (_stage3_ref, _stage3_handle) = Stage3::spawn(None, Stage3, ()).await?;

    println!("Actor system started. Press Ctrl+C to exit.");

    // Keep running
    tokio::signal::ctrl_c().await?;
    println!("Shutting down...");

    Ok(())
}
