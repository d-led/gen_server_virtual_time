// Generated from ActorSimulation DSL
// Default callback implementation for: worker3
//
// CUSTOMIZE THIS CLASS to add your own behavior!

package com.example.actors;

/**
 * Default implementation of Worker3Callbacks.
 * Modify this class to add custom behavior.
 */
public class Worker3CallbacksImpl implements Worker3Callbacks {
  @Override
  public void onProcessTask() {
    // TODO: Implement custom behavior for process_task
    System.out.println("Worker3: Received process_task message");
  }

}
