// Generated from ActorSimulation DSL
// Main entry point for vlingo-loadbalanced

package com.example.actors;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;

/**
 * Main class to start the VLINGO XOOM actor system.
 */
public class Main {
  public static void main(String[] args) {
    System.out.println("Starting VLINGO XOOM actor system...");

    final World world = World.startWithDefaults("vlingo-loadbalanced");

    try {
      // Spawn all actors
LoadBalancerProtocol loadBalancer = world.actorFor(
      LoadBalancerProtocol.class,
      Definition.has(LoadBalancerActor.class,
        Definition.parameters(null, null))
    );

Worker1Protocol worker1 = world.actorFor(
      Worker1Protocol.class,
      Definition.has(Worker1Actor.class,
        Definition.parameters(null, null))
    );

Worker2Protocol worker2 = world.actorFor(
      Worker2Protocol.class,
      Definition.has(Worker2Actor.class,
        Definition.parameters(null, null))
    );

Worker3Protocol worker3 = world.actorFor(
      Worker3Protocol.class,
      Definition.has(Worker3Actor.class,
        Definition.parameters(null, null))
    );

ResultCollectorProtocol resultCollector = world.actorFor(
      ResultCollectorProtocol.class,
      Definition.has(ResultCollectorActor.class,
        Definition.parameters(null, null))
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
