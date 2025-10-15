// Generated from ActorSimulation DSL
// Actor implementation for: processor

package com.example.actors;

import io.vlingo.xoom.actors.Actor;

import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Processor.
 * This actor implements the ProcessorProtocol interface.
 */
public class ProcessorActor extends Actor implements ProcessorProtocol {
  private final ProcessorCallbacks callbacks;
  private final List<ProcessorProtocol> targets;

  /**
   * Constructor for ProcessorActor.
   */
  @SuppressWarnings("unchecked")
  public ProcessorActor(ProcessorCallbacks callbacks, List<ProcessorProtocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new ProcessorCallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();
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
