package com.example.actors;

import io.vlingo.xoom.actors.Actor;
import io.vlingo.xoom.actors.ActorProxyBase;
import io.vlingo.xoom.actors.Address;
import io.vlingo.xoom.actors.DeadLetter;
import io.vlingo.xoom.actors.Definition.SerializationProxy;
import io.vlingo.xoom.actors.LocalMessage;
import io.vlingo.xoom.actors.Mailbox;
import io.vlingo.xoom.actors.Proxy;
import io.vlingo.xoom.actors.Returns;
import io.vlingo.xoom.common.Completes;
import io.vlingo.xoom.common.SerializableConsumer;
import com.example.actors.LoadBalancerProtocol;

public class LoadBalancerProtocol__Proxy extends ActorProxyBase<com.example.actors.LoadBalancerProtocol> implements com.example.actors.LoadBalancerProtocol, Proxy {

  private static final String distributeWorkRepresentation1 = "distributeWork()";

  private final Actor actor;
  private final Mailbox mailbox;

  public LoadBalancerProtocol__Proxy(final Actor actor, final Mailbox mailbox) {
    super(com.example.actors.LoadBalancerProtocol.class, SerializationProxy.from(actor.definition()), actor.address());
    this.actor = actor;
    this.mailbox = mailbox;
  }

  public LoadBalancerProtocol__Proxy() {
    super();
    this.actor = null;
    this.mailbox = null;
  }


  public Address address() {
    return actor.address();
  }

  public boolean equals(final Object other) {
    if (this == other) return true;
    if (other == null) return false;
    if (other.getClass() != getClass()) return false;
    return address().equals(Proxy.from(other).address());
  }

  public int hashCode() {
    return 31 + getClass().hashCode() + actor.address().hashCode();
  }

  public String toString() {
    return "LoadBalancerProtocol[address=" + actor.address() + "]";
  }


  public void distributeWork() {
    if (!actor.isStopped()) {
      ActorProxyBase<LoadBalancerProtocol> self = this;
      final SerializableConsumer<LoadBalancerProtocol> consumer = (actor) -> actor.distributeWork();
      if (mailbox.isPreallocated()) { mailbox.send(actor, LoadBalancerProtocol.class, consumer, null, distributeWorkRepresentation1); }
      else { mailbox.send(new LocalMessage<LoadBalancerProtocol>(actor, LoadBalancerProtocol.class, consumer, distributeWorkRepresentation1)); }
    } else {
      actor.deadLetters().failedDelivery(new DeadLetter(actor, distributeWorkRepresentation1));
    }
  }
}
