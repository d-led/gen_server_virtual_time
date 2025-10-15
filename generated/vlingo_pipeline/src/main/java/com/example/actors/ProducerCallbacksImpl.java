// Generated from ActorSimulation DSL
// Default callback implementation for: producer
//
// CUSTOMIZE THIS CLASS to add your own behavior!

package com.example.actors;

/**
 * Default implementation of ProducerCallbacks.
 * Modify this class to add custom behavior.
 */
public class ProducerCallbacksImpl implements ProducerCallbacks {
  @Override
  public void onData() {
    // TODO: Implement custom behavior for data
    System.out.println("Producer: Sending data message");
  }

}
