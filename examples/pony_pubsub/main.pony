// Generated from ActorSimulation DSL
// Main entry point for pubsub_actors

use "console_logger"
use "publisher"
use "subscriber1"
use "subscriber2"
use "subscriber3"

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """

    // Create thread-safe console logger
    let logger = ConsoleLogger(env.out)

    // Spawn all actors
    let publisher = Publisher(env, logger)
    let subscriber1 = Subscriber1(env, logger)
    let subscriber2 = Subscriber2(env, logger)
    let subscriber3 = Subscriber3(env, logger)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
