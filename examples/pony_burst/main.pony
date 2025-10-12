// Generated from ActorSimulation DSL
// Main entry point for burst_actors

use "console_logger"
use "processor"
use "burst_generator"

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """

    // Create thread-safe console logger
    let logger = ConsoleLogger(env.out)

    // Spawn all actors
    let processor = Processor(env, logger)
    let burst_generator = BurstGenerator(env, logger)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
