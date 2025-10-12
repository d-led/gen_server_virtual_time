// Generated from ActorSimulation DSL
// Main entry point for loadbalanced_actors

use "load_balancer"
use "server1"
use "server2"
use "server3"
use "database"

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """

    // Spawn all actors
    let load_balancer = LoadBalancer(env)
    let server1 = Server1(env)
    let server2 = Server2(env)
    let server3 = Server3(env)
    let database = Database(env)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
