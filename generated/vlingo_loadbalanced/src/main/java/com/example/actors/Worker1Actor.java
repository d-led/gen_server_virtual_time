// Generated from ActorSimulation DSL
// Actor implementation for: worker1

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.common.Scheduled;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Worker1.
 * This actor implements the Worker1Protocol interface.
 */
public class Worker1Actor extends Actor implements Worker1Protocol, Scheduled<Object> {
  private final Worker1Callbacks callbacks;
  private final List<Worker1Protocol> targets;

  /**
   * Constructor for Worker1Actor.
   */
  @SuppressWarnings("unchecked")
  public Worker1Actor(Worker1Callbacks callbacks, List<Worker1Protocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new Worker1CallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();

    // Schedule periodic message sending
    scheduler().schedule(
      selfAs(Scheduled.class),
      null,
      200L,
      200L
    );
  }

  @Override
  public void processTask() {
      callbacks.onProcessTask();
    // Send to all targets
    for (var target : targets) {
      target.processTask();
    }

  }


  @Override
  public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
    processTask();
  }


  @Override
  public void stop() {
    super.stop();
  }
}
