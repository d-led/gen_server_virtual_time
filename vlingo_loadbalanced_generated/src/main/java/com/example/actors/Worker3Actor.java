// Generated from ActorSimulation DSL
// Actor implementation for: worker3

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Worker3.
 * This actor implements the Worker3Protocol interface.
 */
public class Worker3Actor extends Actor implements Worker3Protocol {
  private final Worker3Callbacks callbacks;
  private final List<Worker3Protocol> targets;

  private int sendCount = 0;

  /**
   * Constructor for Worker3Actor.
   */
  public Worker3Actor(Worker3Callbacks callbacks, List<Worker3Protocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new Worker3CallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();
  }

  @Override
  public void processTask() {
      callbacks.onProcessTask();
    // Send to all targets
    for (var target : targets) {
      target.processTask();
    }
    sendCount++;

  }


  @Override
  public void stop() {
    super.stop();
  }
}
