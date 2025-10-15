// Generated from ActorSimulation DSL
// Actor implementation for: producer

package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.common.Scheduled;
import java.util.List;
import java.util.ArrayList;

/**
 * Actor implementation for Producer.
 * This actor implements the ProducerProtocol interface.
 */
public class ProducerActor extends Actor implements ProducerProtocol, Scheduled<Object> {
  private final ProducerCallbacks callbacks;
  private final List<ProducerProtocol> targets;

  /**
   * Constructor for ProducerActor.
   */
  @SuppressWarnings("unchecked")
  public ProducerActor(ProducerCallbacks callbacks, List<ProducerProtocol> targets) {
    this.callbacks = (callbacks != null) ? callbacks : new ProducerCallbacksImpl();
    this.targets = (targets != null) ? targets : new ArrayList<>();

    // Schedule rate-based message sending
    scheduler().schedule(
      selfAs(Scheduled.class),
      null,
      10L,
      10L
    );
  }

  @Override
  public void data() {
      callbacks.onData();
    // Send to all targets
    for (var target : targets) {
      target.data();
    }

  }


  @Override
  public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
    data();
  }


  @Override
  public void stop() {
    super.stop();
  }
}
