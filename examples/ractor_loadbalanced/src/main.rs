// Generated from ActorSimulation DSL
// Main entry point for loadbalanced_actors

use loadbalanced_actors::actors::database::Database;
use loadbalanced_actors::actors::load_balancer::LoadBalancer;
use loadbalanced_actors::actors::server1::Server1;
use loadbalanced_actors::actors::server2::Server2;
use loadbalanced_actors::actors::server3::Server3;
use ractor::Actor;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting actor system...");

    // Spawn all actors
    let (_database_ref, _database_handle) = Database::spawn(None, Database, ()).await?;
    let (_load_balancer_ref, _load_balancer_handle) =
        LoadBalancer::spawn(None, LoadBalancer, ()).await?;

    let (_server1_ref, _server1_handle) = Server1::spawn(None, Server1, ()).await?;
    let (_server2_ref, _server2_handle) = Server2::spawn(None, Server2, ()).await?;
    let (_server3_ref, _server3_handle) = Server3::spawn(None, Server3, ()).await?;

    println!("Actor system started. Press Ctrl+C to exit.");

    // Keep running
    tokio::signal::ctrl_c().await?;
    println!("Shutting down...");

    Ok(())
}
