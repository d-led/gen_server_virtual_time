# vlingo-loadbalanced

Generated from the [ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time) with
[VLINGO XOOM Actors](https://docs.vlingo.io/xoom-actors).

## Run it

```bash
mvn test                     # the tests, which own time: none of them waits for a timer
mvn compile exec:exec        # the same actors on the wall clock, briefly, then it stops
```

Requires Java 11+ and Maven 3.6+.

## What is where

| file | what |
|------|------|
| `src/main/java/**/Main.java` | the actors on the wall clock, for a moment |
| `src/main/java/**/*Actor.java` | the generated actors, each taking its `Scheduler` |
| `src/main/java/**/*Protocol.java` | the messages an actor takes |
| `src/main/java/**/*CallbacksImpl.java` | **your behaviour goes here** |
| `src/test/java/**/ManualScheduler.java` | the clock the tests own |
| `src/test/java/**/*ActorTest.java` | the tests |

## The time the actors wait in belongs to the tests

An actor that sends every 50ms would make a test of it take as long as the test runs.
The generated actors take their `Scheduler` as a constructor argument, so a test hands them one
whose time it controls, and says how much time has passed:

```java
clock = new ManualScheduler();
actor =
    world.actorFor(
        LoadBalancerProtocol.class,
        Definition.has(
            LoadBalancerActor.class, Definition.parameters(counting, new ArrayList<>(), clock)));

actor.distributeWork();                    // the constructor runs: the timer is armed
clock.advanceBy(49);   // a millisecond short of the interval
assertEquals(before, sent.get());      // nothing has been sent
clock.advanceBy(1);                    // the interval, on the instant
assertEquals(before + 1, sent.get());  // and one send
```

Nothing in the test waits for a timer. The mailbox is still asynchronous, so the test waits
briefly — XOOM's `TestUntil` — for the delivery of what the clock made due, and for nothing else.
Production passes no scheduler and gets the stage's, so the same actor waits on the wall clock
unchanged.

## Learn more

- [VLINGO XOOM documentation](https://docs.vlingo.io/xoom-actors)
- [The ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time)
