# vlingo-loadbalanced

Generated from ActorSimulation DSL using VLINGO XOOM Actors.

## About

This project uses [VLINGO XOOM Actors](https://docs.vlingo.io/xoom-actors), a Java actor framework that provides:

- **Type Safety** - Protocol-based messaging with interfaces
- **Reactive Foundation** - Built for distributed, event-driven systems
- **Scheduler Integration** - Built-in scheduling for periodic tasks
- **Production Ready** - Battle-tested in enterprise applications

The code is generated from a high-level Elixir DSL and provides:
- Type-safe actor implementations
- Protocol interfaces for messaging
- Callback interfaces for customization
- JUnit 5 test suites
- Production-ready code

## Prerequisites

- **Java 11+** (Java 17 or 21 recommended)
- **Maven 3.6+**

## Building

```bash
# Build the project
mvn clean compile

# Package as JAR
mvn package
```

## Running

```bash
# Run with Maven
mvn exec:java

# Or run the packaged JAR
java -jar target/vlingo-loadbalanced-1.0-SNAPSHOT-jar-with-dependencies.jar
```

## Testing

```bash
# Run all tests
mvn test

# Run with verbose output
mvn test -X

# Run specific test class
mvn test -Dtest=YourActorTest
```

## Customizing Behavior

The generated actor code uses callback interfaces to allow customization WITHOUT
modifying generated files:

1. Find the `*CallbacksImpl.java` files in `src/main/java`
2. Implement your custom logic in the callback methods
3. Rebuild the project

The generated actor code will automatically call your callbacks.

## Project Structure

```
src/
├── main/
│   └── java/
│       ├── Main.java              # Entry point
│       ├── *Protocol.java         # Actor protocol interfaces (DO NOT EDIT)
│       ├── *Actor.java            # Actor implementations (DO NOT EDIT)
│       ├── *Callbacks.java        # Callback interfaces (DO NOT EDIT)
│       └── *CallbacksImpl.java    # Callback implementations (EDIT THIS!)
└── test/
    └── java/
        └── *ActorTest.java        # JUnit 5 tests (expand as needed)
```

## CI/CD

This project includes a GitHub Actions workflow that:
- Builds on Ubuntu, macOS, and Windows
- Tests with Java 11, 17, and 21
- Publishes test results
- Validates the build with each commit

## Learn More

- [VLINGO XOOM Documentation](https://docs.vlingo.io/)
- [VLINGO XOOM Actors Guide](https://docs.vlingo.io/xoom-actors)
- [VLINGO XOOM GitHub](https://github.com/vlingo)
- [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)

## License

Generated code is provided as-is for your use.
