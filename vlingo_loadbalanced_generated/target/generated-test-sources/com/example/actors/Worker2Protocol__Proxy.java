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
import com.example.actors.Worker2Protocol;

public class Worker2Protocol__Proxy extends ActorProxyBase<com.example.actors.Worker2Protocol> implements com.example.actors.Worker2Protocol, Proxy {

  private static final String processTaskRepresentation1 = "processTask()";

  private final Actor actor;
  private final Mailbox mailbox;

  public Worker2Protocol__Proxy(final Actor actor, final Mailbox mailbox) {
    super(com.example.actors.Worker2Protocol.class, SerializationProxy.from(actor.definition()), actor.address());
    this.actor = actor;
    this.mailbox = mailbox;
  }

  public Worker2Protocol__Proxy() {
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
    return "Worker2Protocol[address=" + actor.address() + "]";
  }


  public void processTask() {
    if (!actor.isStopped()) {
      ActorProxyBase<Worker2Protocol> self = this;
      final SerializableConsumer<Worker2Protocol> consumer = (actor) -> actor.processTask();
      if (mailbox.isPreallocated()) { mailbox.send(actor, Worker2Protocol.class, consumer, null, processTaskRepresentation1); }
      else { mailbox.send(new LocalMessage<Worker2Protocol>(actor, Worker2Protocol.class, consumer, processTaskRepresentation1)); }
    } else {
      actor.deadLetters().failedDelivery(new DeadLetter(actor, processTaskRepresentation1));
    }
  }
}
