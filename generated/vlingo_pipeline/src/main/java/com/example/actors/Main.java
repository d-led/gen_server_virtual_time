// Generated from ActorSimulation DSL
// Main entry point for pipeline-actors

package com.example.actors;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;

/**
 * Main class to start the VLINGO XOOM actor system.
 */
public class Main {
  public static void main(String[] args) {
    System.out.println("Starting VLINGO XOOM actor system...");

    final World world = World.startWithDefaults("pipeline-actors");

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
        Definition.parameters((ProducerCallbacks) null, new java.util.ArrayList<>()))
    );

ConsumerProtocol consumer = world.actorFor(
      ConsumerProtocol.class,
      Definition.has(ConsumerActor.class,
        Definition.parameters((ConsumerCallbacks) null))
    );


      System.out.println("Actor system started. Press Ctrl+C to exit.");

      // Keep running
      Thread.currentThread().join();
    } catch (InterruptedException e) {
      System.out.println("System interrupted, shutting down...");
    } finally {
      world.terminate();
    }
  }
}
