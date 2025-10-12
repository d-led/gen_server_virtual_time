// Generated from ActorSimulation DSL
// Main entry point for pubsub_actors

use "publisher"
use "subscriber1"
use "subscriber2"
use "subscriber3"

actor Main
  new create(env: Env) =>
    """
    Start the actor system.
    """

    // Spawn all actors
    let publisher = Publisher(env)
    let subscriber1 = Subscriber1(env)
    let subscriber2 = Subscriber2(env)
    let subscriber3 = Subscriber3(env)

    env.out.print("Actor system started. Press Ctrl+C to exit.")
