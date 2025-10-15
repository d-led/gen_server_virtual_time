// Generated from ActorSimulation DSL
// Default callback implementation for: consumer
//
// CUSTOMIZE THIS CLASS to add your own behavior!

package com.example.actors;

/**
 * Default implementation of ConsumerCallbacks.
 * Modify this class to add custom behavior.
 */
public class ConsumerCallbacksImpl implements ConsumerCallbacks {
  @Override
  public void onProcess() {
    // TODO: Implement custom behavior
    System.out.println("Consumer: Processing message");
  }

}
