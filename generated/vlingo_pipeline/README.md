# pipeline-actors

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

An actor that sends every 10ms would make a test of it take as long as the test runs.
The generated actors take their `Scheduler` as a constructor argument: production passes none and
gets the stage's, which is the wall clock, and a test hands the actor a `ManualScheduler` — the
clock the test owns, in `src/test/java` — which fires nothing until the test calls `advanceBy`.
The tests assert the counts that clock produces, down to the millisecond before an interval;
what is left here is what the same actors print on the wall clock:

```shell
$ mvn compile exec:exec
Starting VLINGO XOOM actor system...
Producer: Sending data message
Producer: Sending data message
Running for 300ms...
Stopped.
```

## Learn more

- [VLINGO XOOM documentation](https://docs.vlingo.io/xoom-actors)
- [The ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time)
