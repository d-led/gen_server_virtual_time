// Generated from ActorSimulation DSL
// Default callback implementation for: load_balancer
//
// CUSTOMIZE THIS CLASS to add your own behavior!

package com.example.actors;

/**
 * Default implementation of LoadBalancerCallbacks.
 * Modify this class to add custom behavior.
 */
public class LoadBalancerCallbacksImpl implements LoadBalancerCallbacks {
  @Override
  public void onDistributeWork() {
    // TODO: Implement custom behavior for distribute_work
    System.out.println("LoadBalancer: Sending distribute_work message");
  }

}
