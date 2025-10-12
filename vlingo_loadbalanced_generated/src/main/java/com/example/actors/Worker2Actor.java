// Generated from ActorSimulation DSL
// Actor implementation for: worker2

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Worker2.
 * This actor implements the Worker2Protocol interface.
 */
public class Worker2Actor extends Actor implements Worker2Protocol {
  private final Worker2Callbacks callbacks;
  private final List<Worker2Protocol> targets;

  private int sendCount = 0;

  /**
   * Constructor for Worker2Actor.
   */
  public Worker2Actor(Worker2Callbacks callbacks, List<Worker2Protocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new Worker2CallbacksImpl();
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
