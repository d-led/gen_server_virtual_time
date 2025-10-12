// Generated from ActorSimulation DSL
// Actor implementation for: worker2

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.common.Scheduled;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Worker2.
 * This actor implements the Worker2Protocol interface.
 */
public class Worker2Actor extends Actor implements Worker2Protocol, Scheduled<Object> {
  private final Worker2Callbacks callbacks;
  private final List<Worker2Protocol> targets;

  /**
   * Constructor for Worker2Actor.
   */
  @SuppressWarnings("unchecked")
  public Worker2Actor(Worker2Callbacks callbacks, List<Worker2Protocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new Worker2CallbacksImpl();
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
