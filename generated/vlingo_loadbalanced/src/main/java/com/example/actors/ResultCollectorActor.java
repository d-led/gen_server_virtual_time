// Generated from ActorSimulation DSL
// Actor implementation for: result_collector

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.common.Scheduled;


/**
 * Actor implementation for ResultCollector.
 * This actor implements the ResultCollectorProtocol interface.
 */
public class ResultCollectorActor extends Actor implements ResultCollectorProtocol, Scheduled<Object> {
  private final ResultCollectorCallbacks callbacks;

  /**
   * Constructor for ResultCollectorActor.
   */
  @SuppressWarnings("unchecked")
  public ResultCollectorActor(ResultCollectorCallbacks callbacks, io.vlingo.xoom.common.Scheduler timers) {
    this.callbacks = (callbacks != null) ? callbacks : new ResultCollectorCallbacksImpl();

    final io.vlingo.xoom.common.Scheduler clock = (timers != null) ? timers : scheduler();

    // Schedule rate-based message sending
    clock.schedule(
      selfAs(Scheduled.class),
      null,
      500L,
      500L
    );
  }

  @Override
  public void aggregateResults() {
      callbacks.onAggregateResults();

  }


  @Override
  public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
    aggregateResults();
  }


  @Override
  public void stop() {
    super.stop();
  }
}
