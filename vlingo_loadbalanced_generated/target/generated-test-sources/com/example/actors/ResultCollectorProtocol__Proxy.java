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
import com.example.actors.ResultCollectorProtocol;

public class ResultCollectorProtocol__Proxy extends ActorProxyBase<com.example.actors.ResultCollectorProtocol> implements com.example.actors.ResultCollectorProtocol, Proxy {

  private static final String aggregateResultsRepresentation1 = "aggregateResults()";

  private final Actor actor;
  private final Mailbox mailbox;

  public ResultCollectorProtocol__Proxy(final Actor actor, final Mailbox mailbox) {
    super(com.example.actors.ResultCollectorProtocol.class, SerializationProxy.from(actor.definition()), actor.address());
    this.actor = actor;
    this.mailbox = mailbox;
  }

  public ResultCollectorProtocol__Proxy() {
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
    return "ResultCollectorProtocol[address=" + actor.address() + "]";
  }


  public void aggregateResults() {
    if (!actor.isStopped()) {
      ActorProxyBase<ResultCollectorProtocol> self = this;
      final SerializableConsumer<ResultCollectorProtocol> consumer = (actor) -> actor.aggregateResults();
      if (mailbox.isPreallocated()) { mailbox.send(actor, ResultCollectorProtocol.class, consumer, null, aggregateResultsRepresentation1); }
      else { mailbox.send(new LocalMessage<ResultCollectorProtocol>(actor, ResultCollectorProtocol.class, consumer, aggregateResultsRepresentation1)); }
    } else {
      actor.deadLetters().failedDelivery(new DeadLetter(actor, aggregateResultsRepresentation1));
    }
  }
}
