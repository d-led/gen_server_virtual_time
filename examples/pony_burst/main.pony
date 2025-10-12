// Generated from ActorSimulation DSL
// Main entry point for burst_actors

use "processor"
use "burst_generator"

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """
    
    // Spawn all actors
    let processor = Processor(env)
    let burst_generator = BurstGenerator(env)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
