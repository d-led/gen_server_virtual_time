// Generated from ActorSimulation DSL
// Actor implementation for: load_balancer

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for LoadBalancer.
 * This actor implements the LoadBalancerProtocol interface.
 */
public class LoadBalancerActor extends Actor implements LoadBalancerProtocol {
  private final LoadBalancerCallbacks callbacks;
  private final List<LoadBalancerProtocol> targets;

  private int sendCount = 0;

  /**
   * Constructor for LoadBalancerActor.
   */
  public LoadBalancerActor(LoadBalancerCallbacks callbacks, List<LoadBalancerProtocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new LoadBalancerCallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();
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
  public void stop() {
    super.stop();
  }
}
