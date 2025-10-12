// Generated from ActorSimulation DSL
// Callback interface for: load_balancer
//
// IMPLEMENT THIS INTERFACE to add custom behavior!

package com.example.actors;

/**
 * Callback interface for LoadBalancer actor.
 * Implement this interface to customize actor behavior.
 */
public interface LoadBalancerCallbacks {
  void onDistributeWork();
}
