// Generated from ActorSimulation DSL
// Main entry point for pipeline_actors

use "source"
use "stage1"
use "stage2"
use "stage3"
use "sink"

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """
    
    // Spawn all actors
    let source = Source(env)
    let stage1 = Stage1(env)
    let stage2 = Stage2(env)
    let stage3 = Stage3(env)
    let sink = Sink(env)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
