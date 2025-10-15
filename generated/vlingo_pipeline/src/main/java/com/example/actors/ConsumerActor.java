// Generated from ActorSimulation DSL
// Actor implementation for: consumer

package com.example.actors;

import io.vlingo.xoom.actors.Actor;



/**
 * Actor implementation for Consumer.
 * This actor implements the ConsumerProtocol interface.
 */
public class ConsumerActor extends Actor implements ConsumerProtocol {
  private final ConsumerCallbacks callbacks;

  /**
   * Constructor for ConsumerActor.
   */
  @SuppressWarnings("unchecked")
  public ConsumerActor(ConsumerCallbacks callbacks) {
    this.callbacks = (callbacks != null) ? callbacks : new ConsumerCallbacksImpl();
  }

  @Override
  public void process() {
    logger().info(getClass().getSimpleName() + " processing...");
    // Send to targets
    sendToTargets();
  }

  private void sendToTargets() {
    // No targets defined
  }



  @Override
  public void stop() {
    super.stop();
  }
}
