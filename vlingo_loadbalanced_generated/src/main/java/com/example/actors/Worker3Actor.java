// Generated from ActorSimulation DSL
// Actor implementation for: worker3

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.common.Scheduled;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Worker3.
 * This actor implements the Worker3Protocol interface.
 */
public class Worker3Actor extends Actor implements Worker3Protocol, Scheduled<Object> {
  private final Worker3Callbacks callbacks;
  private final List<Worker3Protocol> targets;

  /**
   * Constructor for Worker3Actor.
   */
  @SuppressWarnings("unchecked")
  public Worker3Actor(Worker3Callbacks callbacks, List<Worker3Protocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new Worker3CallbacksImpl();
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
