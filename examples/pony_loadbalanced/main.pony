// Generated from ActorSimulation DSL
// Main entry point for loadbalanced_actors

use "console_logger"
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

    // Create thread-safe console logger
    let logger = ConsoleLogger(env.out)

    // Spawn all actors
    let load_balancer = LoadBalancer(env, logger)
    let server1 = Server1(env, logger)
    let server2 = Server2(env, logger)
    let server3 = Server3(env, logger)
    let database = Database(env, logger)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
