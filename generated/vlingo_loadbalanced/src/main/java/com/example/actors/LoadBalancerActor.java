// Generated from ActorSimulation DSL
// Actor implementation for: load_balancer

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.common.Scheduled;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for LoadBalancer.
 * This actor implements the LoadBalancerProtocol interface.
 */
public class LoadBalancerActor extends Actor implements LoadBalancerProtocol, Scheduled<Object> {
  private final LoadBalancerCallbacks callbacks;
  private final List<LoadBalancerProtocol> targets;

  /**
   * Constructor for LoadBalancerActor.
   */
  @SuppressWarnings("unchecked")
  public LoadBalancerActor(LoadBalancerCallbacks callbacks, List<LoadBalancerProtocol> targets, io.vlingo.xoom.common.Scheduler timers) {
    this.callbacks = (callbacks != null) ? callbacks : new LoadBalancerCallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();

    final io.vlingo.xoom.common.Scheduler clock = (timers != null) ? timers : scheduler();

    // Schedule periodic message sending
    clock.schedule(
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

  }


  @Override
  public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
    distributeWork();
  }


  @Override
  public void stop() {
    super.stop();
  }
}
