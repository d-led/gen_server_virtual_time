// Generated from ActorSimulation DSL
// Actor implementation for: result_collector

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.actors.Scheduled;
import io.vlingo.xoom.common.Cancellable;


/**
 * Actor implementation for ResultCollector.
 * This actor implements the ResultCollectorProtocol interface.
 */
public class ResultCollectorActor extends Actor implements ResultCollectorProtocol, Scheduled<Object> {
  private final ResultCollectorCallbacks callbacks;

  private Cancellable scheduled;
  private int sendCount = 0;

  /**
   * Constructor for ResultCollectorActor.
   */
  public ResultCollectorActor(ResultCollectorCallbacks callbacks) {
    this.callbacks = (callbacks != null) ? callbacks : new ResultCollectorCallbacksImpl();
    // Schedule rate-based message sending
    this.scheduled = scheduler().schedule(
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
  public void intervalSignal(Scheduled<Object> scheduled, Object data) {
    // Timer fired, send message
    aggregateResults();
  }

  @Override
  public void stop() {
    if (scheduled != null) {
      scheduled.cancel();
    }
    super.stop();
  }
}
