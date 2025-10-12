# burst_actors

Generated from ActorSimulation DSL using Phony (Go actor library).

## About

This project uses [Phony](https://github.com/Arceliar/phony), a Pony-inspired
actor library for Go that provides:

- **Zero-allocation messaging** - Efficient message passing
- **Automatic goroutine management** - No goroutine leaks
- **Backpressure support** - Built-in flow control
- **Lock-free** - No mutexes or channels needed

The code is generated from a high-level Elixir DSL and provides:
- Phony actor implementations
- Callback interfaces for customization
- Go test suites
- Production-ready code

## Prerequisites

- **Go 1.21+**
- **Git** (for go modules)

## Building

```bash
# Download dependencies
go mod download

# Build
go build -o burst_actors .

# Run
./burst_actors
```

## Testing

```bash
# Run tests
go test -v ./...

# Or use Make
make test
```

## Customizing Behavior

The generated actor code uses callback interfaces to allow customization:

1. Find the `*Callbacks` interface in each actor file
2. Modify the `Default*Callbacks` implementation
3. Add your custom logic in the callback methods
4. Rebuild

The generated actor code will automatically call your callbacks.

## Project Structure

- `main.go` - Entry point and actor spawning
- `*.go` - Generated actor implementations
- `actor_test.go` - Go test suite
- `go.mod` - Module definition
- `Makefile` - Build targets

## CI/CD

This project includes a GitHub Actions workflow that:
- Builds on Ubuntu, macOS, and Windows
- Tests with multiple Go versions
- Validates the build with each commit

## Learn More

- [Phony GitHub](https://github.com/Arceliar/phony)
- [Go Modules](https://go.dev/blog/using-go-modules)
- [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)

## License

Generated code is provided as-is for your use.
