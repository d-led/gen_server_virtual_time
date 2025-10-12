// Generated from ActorSimulation DSL
// Default callback implementation for: result_collector
//
// CUSTOMIZE THIS CLASS to add your own behavior!

package com.example.actors;

/**
 * Default implementation of ResultCollectorCallbacks.
 * Modify this class to add custom behavior.
 */
public class ResultCollectorCallbacksImpl implements ResultCollectorCallbacks {
  @Override
  public void onAggregateResults() {
    // TODO: Implement custom behavior for aggregate_results
    System.out.println("ResultCollector: Sending aggregate_results message");
  }

}
