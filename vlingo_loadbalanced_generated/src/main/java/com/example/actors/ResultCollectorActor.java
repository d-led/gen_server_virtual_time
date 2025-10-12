// Generated from ActorSimulation DSL
// Actor implementation for: result_collector

package com.example.actors;

import io.vlingo.xoom.actors.Actor;


/**
 * Actor implementation for ResultCollector.
 * This actor implements the ResultCollectorProtocol interface.
 */
public class ResultCollectorActor extends Actor implements ResultCollectorProtocol {
  private final ResultCollectorCallbacks callbacks;

  private int sendCount = 0;

  /**
   * Constructor for ResultCollectorActor.
   */
  public ResultCollectorActor(ResultCollectorCallbacks callbacks) {
    this.callbacks = (callbacks != null) ? callbacks : new ResultCollectorCallbacksImpl();
  }

  @Override
  public void aggregateResults() {
      callbacks.onAggregateResults();

  }


  @Override
  public void stop() {
    super.stop();
  }
}
