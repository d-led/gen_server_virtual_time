// Generated from ActorSimulation DSL
// Main entry point for pipeline_actors

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """

    // Create thread-safe console logger
    let logger = ConsoleLogger(env.out)

    // Spawn all actors
    let source = Source(env, logger)
    let stage1 = Stage1(env, logger)
    let stage2 = Stage2(env, logger)
    let stage3 = Stage3(env, logger)
    let sink = Sink(env, logger)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
