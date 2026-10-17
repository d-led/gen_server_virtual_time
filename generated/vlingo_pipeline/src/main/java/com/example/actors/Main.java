// Generated from ActorSimulation DSL
// Main entry point for pipeline-actors

package com.example.actors;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;

/**
 * Main class to start the VLINGO XOOM actor system on the wall clock.
 */
public class Main {
  /** How long the actors run: long enough to see them work, short enough for a demo. */
  private static final long RUN_MILLIS = 300L;

  /** No scheduler is given, so the actors wait on the wall clock. */
  public static void main(String[] args) throws InterruptedException {
    System.out.println("Starting VLINGO XOOM actor system...");

    final World world = World.startWithDefaults("pipeline-actors");

    // The world's scheduler has threads of its own, and terminating the world
    // does not stop them, so a program that is done closes the scheduler too.
    final io.vlingo.xoom.common.Scheduler timers = world.stage().scheduler();

    try {
      // Spawn all actors
ProcessorProtocol processor = world.actorFor(
      ProcessorProtocol.class,
      Definition.has(ProcessorActor.class,
        Definition.parameters((ProcessorCallbacks) null, new java.util.ArrayList<>()))
    );

ProducerProtocol producer = world.actorFor(
      ProducerProtocol.class,
      Definition.has(ProducerActor.class,
        Definition.parameters((ProducerCallbacks) null, new java.util.ArrayList<>(), (io.vlingo.xoom.common.Scheduler) null))
    );

ConsumerProtocol consumer = world.actorFor(
      ConsumerProtocol.class,
      Definition.has(ConsumerActor.class,
        Definition.parameters((ConsumerCallbacks) null))
    );


      System.out.println("Running for " + RUN_MILLIS + "ms...");
      Thread.sleep(RUN_MILLIS);
    } finally {
      world.terminate();
      timers.close();
    }

    System.out.println("Stopped.");

    // The actor world leaves threads of its own behind even after it is
    // terminated and its scheduler closed, so a demo that is over says so to the
    // JVM instead of waiting for them.
    System.exit(0);
  }
}
