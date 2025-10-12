// Generated from ActorSimulation DSL
// Actor implementation for: worker1

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Worker1.
 * This actor implements the Worker1Protocol interface.
 */
public class Worker1Actor extends Actor implements Worker1Protocol {
  private final Worker1Callbacks callbacks;
  private final List<Worker1Protocol> targets;

  private int sendCount = 0;

  /**
   * Constructor for Worker1Actor.
   */
  public Worker1Actor(Worker1Callbacks callbacks, List<Worker1Protocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new Worker1CallbacksImpl();
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
