# VLINGO XOOM Generator

Generate production-ready Java actor systems from ActorSimulation DSL using
VLINGO XOOM Actors.

## Overview

VLINGO XOOM is a Java framework for building reactive, event-driven distributed
systems. This generator translates ActorSimulation definitions into complete
Maven projects with:

- **Type-safe actor implementations** - Protocol interfaces for messaging
- **Scheduler integration** - Built-in periodic message sending
- **Callback interfaces** - Customize behavior without touching generated code
- **JUnit 5 tests** - Full test coverage out of the box
- **Maven build** - Complete pom.xml with all dependencies
- **CI/CD ready** - GitHub Actions workflow included

## Quick Start

```elixir
alias ActorSimulation, as: Sim
alias ActorSimulation.VlingoGenerator, as: VG

# Define your actor system
simulation = Sim.new()
|> Sim.add_actor(:load_balancer,
    send_pattern: {:periodic, 50, :distribute_work},
    targets: [:worker1, :worker2, :worker3])
|> Sim.add_actor(:worker1,
    send_pattern: {:periodic, 200, :process_task},
    targets: [:result_collector])
|> Sim.add_actor(:worker2,
    send_pattern: {:periodic, 200, :process_task},
    targets: [:result_collector])
|> Sim.add_actor(:worker3,
    send_pattern: {:periodic, 200, :process_task},
    targets: [:result_collector])
|> Sim.add_actor(:result_collector)

# Generate complete Java project
{:ok, files} = VG.generate(simulation,
  project_name: "load-balancer",
  group_id: "com.example.actors",
  vlingo_version: "1.11.1",
  enable_callbacks: true)

VG.write_to_directory(files, "vlingo_output/")
```

## Building and Running

```bash
cd vlingo_output

# Compile
mvn clean compile

# Run tests
mvn test

# Run application, which runs for a moment and stops
# (a forked JVM: VLINGO compiles an actor's proxy at runtime)
mvn compile exec:exec

# Package as JAR
mvn package
java -jar target/load-balancer-1.0-SNAPSHOT-jar-with-dependencies.jar
```

## Generated Project Structure

```
vlingo_output/
├── pom.xml                              # Maven configuration
├── README.md                            # Build instructions
├── .github/workflows/ci.yml             # CI pipeline
└── src/
    ├── main/java/com/example/actors/
    │   ├── Main.java                    # Entry point
    │   ├── LoadBalancerProtocol.java    # Protocol interface (DO NOT EDIT)
    │   ├── LoadBalancerActor.java       # Actor implementation (DO NOT EDIT)
    │   ├── LoadBalancerCallbacks.java   # Callback interface (DO NOT EDIT)
    │   ├── LoadBalancerCallbacksImpl.java # Callback impl (EDIT THIS!)
    │   └── ... (other actors)
    └── test/java/com/example/actors/
        ├── LoadBalancerActorTest.java   # JUnit 5 tests, on a clock the test owns
        ├── ManualScheduler.java         # the clock the tests own
        └── ... (other tests)
```

## Key Features

### Protocol-Based Messaging

VLINGO XOOM uses protocol interfaces for type-safe messaging:

```java
// Generated protocol interface
public interface LoadBalancerProtocol {
  void distributeWork();
}

// Generated actor implementation
public class LoadBalancerActor extends Actor
    implements LoadBalancerProtocol, Scheduled<Object> {

  @Override
  public void distributeWork() {
    callbacks.onDistributeWork();
    // Send to targets...
  }
}
```

### Scheduler Integration

Periodic patterns use a scheduler the actor is given, so the test decides how
time passes and production gets the stage's scheduler, which is the wall clock:

```java
// Automatically generated from:
// send_pattern: {:periodic, 50, :distribute_work}

public LoadBalancerActor(
    LoadBalancerCallbacks callbacks, List<LoadBalancerProtocol> targets,
    io.vlingo.xoom.common.Scheduler timers) {
  ...
  final io.vlingo.xoom.common.Scheduler clock =
      (timers != null) ? timers : scheduler();

  clock.schedule(
    selfAs(Scheduled.class),
    null,
    50L,  // initial delay
    50L   // period
  );
}

@Override
public void intervalSignal(Scheduled<Object> scheduled, Object data) {
  distributeWork();
}
```

The generated test hands the actor a `ManualScheduler` and says how much time
has passed, instead of waiting for it:

```java
clock.advanceBy(INTERVAL_MILLIS - 1);
assertEquals(before, sent.get());   // nothing yet
clock.advanceBy(1);
assertEquals(before + 1, sent.get());
```

Nothing in the test waits for a timer. The mailbox is still asynchronous, so the
test waits briefly — VLINGO's `TestUntil` — for the delivery of what the clock
made due, and for nothing else.

### Customizable Callbacks

Add your business logic without modifying generated code:

```java
// LoadBalancerCallbacksImpl.java (YOUR CODE HERE!)
public class LoadBalancerCallbacksImpl implements LoadBalancerCallbacks {

  @Override
  public void onDistributeWork() {
    // Add your custom logic
    logger.info("Distributing work to workers");
    metrics.increment("work.distributed");
    database.recordEvent("distribution");
  }
}
```

### JUnit 5 Tests

The generated tests put the time in their own hands and assert what the actor
did, with no sleep on the wall clock:

```java
public class LoadBalancerActorTest {
  private static final long INTERVAL_MILLIS = 50L;
  private static final long BOUND_MILLIS = 1000L;

  private World world;
  private ManualScheduler clock;
  private LoadBalancerProtocol actor;
  private final AtomicInteger sent = new AtomicInteger();
  private final TestUntil handled = TestUntil.happenings(1);

  private void count() {
    sent.incrementAndGet();
    handled.happened();
  }

  @BeforeEach
  public void setUp() {
    clock = new ManualScheduler();
    world = World.startWithDefaults("test-world");

    final LoadBalancerCallbacks counting = new LoadBalancerCallbacks() { /* count() */ };

    actor =
        world.actorFor(
            LoadBalancerProtocol.class,
            Definition.has(
                LoadBalancerActor.class, Definition.parameters(counting, clock)));
  }

  @Test
  public void testTheActorSendsWhenTheTestSaysItsIntervalHasPassed() {
    handled.resetHappeningsTo(1);
    actor.distributeWork();
    assertTrue(handled.completesWithin(BOUND_MILLIS));

    final int before = sent.get();

    clock.advanceBy(INTERVAL_MILLIS - 1);
    assertEquals(before, sent.get(), "the actor sent before its interval was up");

    handled.resetHappeningsTo(1);
    clock.advanceBy(1);
    assertTrue(handled.completesWithin(BOUND_MILLIS));
    assertEquals(before + 1, sent.get(), "the actor did not send when its interval was up");
  }
}
```

## Generator Options

```elixir
VlingoGenerator.generate(simulation,
  # Required: Maven artifact name (kebab-case)
  project_name: "my-actors",

  # Optional: Maven group ID (default: "com.example")
  group_id: "com.mycompany.actors",

  # Optional: VLINGO XOOM version (default: "1.11.1")
  vlingo_version: "1.11.1",

  # Optional: Generate callback interfaces (default: true)
  enable_callbacks: true
)
```

## Send Patterns

The generator supports all ActorSimulation send patterns:

```elixir
# Periodic: Every N milliseconds
send_pattern: {:periodic, 100, :tick}
# Generates: clock.schedule(..., 100L, 100L)

# Rate-based: N messages per second
send_pattern: {:rate, 50, :event}
# Generates: clock.schedule(..., 20L, 20L)

# Burst: N messages every interval
send_pattern: {:burst, 10, 500, :batch}
# Generates: clock.schedule(..., 500L, 500L)
```

## Maven Dependencies

The generated `pom.xml` includes:

```xml
<dependencies>
  <!-- VLINGO XOOM Actors -->
  <dependency>
    <groupId>io.vlingo.xoom</groupId>
    <artifactId>xoom-actors</artifactId>
    <version>1.11.1</version>
  </dependency>

  <!-- JUnit 5 for testing -->
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-api</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
  </dependency>
</dependencies>
```

## CI/CD Pipeline

Generated projects include a GitHub Actions workflow that:

- Tests on Ubuntu, macOS, and Windows
- Tests with Java 11 and 21
- Runs JUnit 5 tests with Surefire
- Publishes test results
- Validates compilation

## Performance

VLINGO XOOM provides:

- **High throughput** - Millions of messages per second
- **Low latency** - Microsecond-scale message delivery
- **Scalability** - Thousands of actors per JVM
- **Resource efficiency** - Minimal memory overhead

## Comparison with Other Generators

| Feature          | OMNeT++ | CAF | Pony | Phony | **VLINGO** |
| ---------------- | ------- | --- | ---- | ----- | ---------- |
| Language         | C++     | C++ | Pony | Go    | **Java**   |
| Type Safety      | ✓       | ✓   | ✓✓✓  | ✓     | **✓✓**     |
| Callbacks        | ✗       | ✓   | ✓    | ✓     | **✓**      |
| Scheduler        | ✓       | ✓   | ✓    | ✓     | **✓**      |
| Enterprise Ready | ✓✓✓     | ✓   | ✓    | ✓     | **✓✓✓**    |
| JVM Ecosystem    | ✗       | ✗   | ✗    | ✗     | **✓**      |

## Learn More

- [VLINGO XOOM Documentation](https://docs.vlingo.io/)
- [VLINGO XOOM Actors Guide](https://docs.vlingo.io/xoom-actors)
- [VLINGO GitHub](https://github.com/vlingo)
- [ActorSimulation DSL](../README.md)

## Example: Load Balanced Worker Pool

See `scripts/generate_vlingo_sample.exs` for a complete working example of a
load-balanced worker pool with result aggregation.

```bash
mix run scripts/generate_vlingo_sample.exs
cd generated/vlingo_loadbalanced
mvn test
```

This generates a realistic distributed system with:

- 1 load balancer distributing work (50ms period)
- 3 workers processing tasks (200ms period)
- 1 result collector aggregating results (2 msgs/sec)

All with full JUnit 5 test coverage and customizable callbacks!
