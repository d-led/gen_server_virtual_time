// Generated from ActorSimulation DSL
// Actor implementation for: load_balancer

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.actors.Scheduled;
import io.vlingo.xoom.common.Cancellable;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for LoadBalancer.
 * This actor implements the LoadBalancerProtocol interface.
 */
public class LoadBalancerActor extends Actor implements LoadBalancerProtocol, Scheduled<Object> {
  private final LoadBalancerCallbacks callbacks;
  private final List<LoadBalancerProtocol> targets;

  private Cancellable scheduled;
  private int sendCount = 0;

  /**
   * Constructor for LoadBalancerActor.
   */
  public LoadBalancerActor(LoadBalancerCallbacks callbacks, List<LoadBalancerProtocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new LoadBalancerCallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();
    // Schedule periodic message sending
    this.scheduled = scheduler().schedule(
      selfAs(Scheduled.class),
      null,
      50L,
      50L
    );
  }

  @Override
  public void distributeWork() {
      callbacks.onDistributeWork();
    // Send to all targets
    for (var target : targets) {
      target.distributeWork();
    }
    sendCount++;

  }


  @Override
  public void intervalSignal(Scheduled<Object> scheduled, Object data) {
    // Timer fired, send message
    distributeWork();
  }

  @Override
  public void stop() {
    if (scheduled != null) {
      scheduled.cancel();
    }
    super.stop();
  }
}
