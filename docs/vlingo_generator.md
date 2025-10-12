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

# Run application
mvn exec:java

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
        ├── LoadBalancerActorTest.java   # JUnit 5 tests
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

Periodic patterns use VLINGO's built-in scheduler:

```java
// Automatically generated from:
// send_pattern: {:periodic, 50, :distribute_work}

this.scheduled = scheduler().schedule(
  selfAs(Scheduled.class),
  null,
  50L,  // initial delay
  50L   // period
);

@Override
public void intervalSignal(Scheduled<Object> scheduled, Object data) {
  distributeWork();
}
```

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

Full test coverage generated automatically:

```java
public class LoadBalancerActorTest {
  private World world;
  private LoadBalancerProtocol actor;

  @BeforeEach
  public void setUp() {
    world = World.startWithDefaults("test-world");
    actor = world.actorFor(
      LoadBalancerProtocol.class,
      Definition.has(LoadBalancerActor.class,
        Definition.parameters(null, null))
    );
  }

  @Test
  public void testDistributeWorkMessage() {
    actor.distributeWork();
    // Assertions...
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
# Generates: scheduler().schedule(..., 100L, 100L)

# Rate-based: N messages per second
send_pattern: {:rate, 50, :event}
# Generates: scheduler().schedule(..., 20L, 20L)

# Burst: N messages every interval
send_pattern: {:burst, 10, 500, :batch}
# Generates: scheduler().schedule(..., 500L, 500L)
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
- Tests with Java 11, 17, and 21
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
