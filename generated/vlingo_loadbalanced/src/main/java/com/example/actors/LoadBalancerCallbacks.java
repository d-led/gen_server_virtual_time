// Generated from ActorSimulation DSL
// Callback interface for: load_balancer
// DO NOT EDIT - This file is auto-generated
//
// This interface defines the contract for LoadBalancer callbacks.
// Customize behavior by editing LoadBalancerCallbacksImpl.java

package com.example.actors;

/**
 * Callback interface for LoadBalancer actor.
 * This is the contract - do not modify this interface.
 * Customize behavior in LoadBalancerCallbacksImpl instead.
 */
public interface LoadBalancerCallbacks {
  void onDistributeWork();
}
