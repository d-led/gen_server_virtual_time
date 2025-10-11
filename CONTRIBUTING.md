# Contributing to GenServerVirtualTime

Thank you for your interest in contributing to GenServerVirtualTime! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Code Guidelines](#code-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

## Code of Conduct

This project follows a simple code of conduct:

- Be respectful and inclusive
- Assume good intentions
- Provide constructive feedback
- Focus on the best outcome for the community

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- OTP 25 or later
- Git
- A GitHub account

### Finding Work

1. **Check existing issues:** Look for issues labeled `good first issue` or `help wanted`
2. **Report bugs:** Found a bug? Open an issue first to discuss
3. **Propose features:** Have an idea? Open an issue to discuss before implementing
4. **Improve documentation:** Documentation improvements are always welcome

## Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/your-username/gen_server_virtual_time.git
   cd gen_server_virtual_time
   ```

2. **Install dependencies:**
   ```bash
   mix deps.get
   ```

3. **Verify the setup:**
   ```bash
   mix test
   mix docs
   ```

4. **Create a branch:**
   ```bash
   git checkout -b feature/my-new-feature
   # or
   git checkout -b fix/issue-123
   ```

## Development Workflow

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/virtual_clock_test.exs

# Run with coverage
mix test --cover

# Run with detailed coverage
mix coveralls.html
open cover/excoveralls.html
```

### Code Quality Checks

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Run Credo (code analysis)
mix credo --strict

# Run Dialyzer (type checking)
mix dialyzer

# Run all quality checks
mix format --check-formatted && mix credo --strict && mix dialyzer
```

### Building Documentation

```bash
# Generate documentation
mix docs

# Open documentation in browser
open doc/index.html
```

### Running Examples

```bash
# Run demo scripts
mix run examples/demo.exs
mix run examples/advanced_demo.exs
mix run examples/omnetpp_demo.exs
```

## Code Guidelines

### Style Guidelines

- Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` to automatically format code
- Maximum line length: 120 characters
- Use meaningful variable and function names

### Module Organization

```elixir
defmodule MyModule do
  @moduledoc """
  Brief description of the module.

  ## Examples

      iex> MyModule.function()
      :ok
  """

  # Behaviors and use statements
  use SomeBehavior

  # Aliases
  alias Some.Module

  # Module attributes
  @default_timeout 5000

  # Types
  @type t :: %__MODULE__{}

  # Public functions
  def public_function do
    # ...
  end

  # Private functions
  defp private_function do
    # ...
  end
end
```

### Documentation

- Every public module must have `@moduledoc`
- Every public function must have `@doc`
- Include examples in documentation using doctests
- Use `@spec` for all public functions

Example:

```elixir
@doc """
Advances the virtual clock by the specified duration.

Returns `:ok` on success.

## Parameters

  * `clock` - The PID of the virtual clock
  * `duration` - Duration in milliseconds to advance

## Examples

    iex> {:ok, clock} = VirtualClock.start_link()
    iex> VirtualClock.advance(clock, 1000)
    :ok
"""
@spec advance(pid(), non_neg_integer()) :: :ok
def advance(clock, duration) when is_integer(duration) and duration >= 0 do
  # Implementation
end
```

### Error Handling

- Use pattern matching over try/catch when possible
- Return `{:ok, result}` or `{:error, reason}` tuples for operations that can fail
- Use `!` suffix for functions that raise exceptions
- Document all possible error returns

### Testing

- Write tests for all public functions
- Use descriptive test names
- One assertion per test when possible
- Test both success and failure cases

Example:

```elixir
describe "advance/2" do
  test "advances clock by specified duration" do
    {:ok, clock} = VirtualClock.start_link()
    assert VirtualClock.now(clock) == 0
    
    VirtualClock.advance(clock, 1000)
    assert VirtualClock.now(clock) == 1000
  end

  test "handles negative duration" do
    {:ok, clock} = VirtualClock.start_link()
    
    assert {:error, :invalid_duration} = VirtualClock.advance(clock, -100)
  end
end
```

## Testing Guidelines

### Test Organization

- Group related tests using `describe` blocks
- Use descriptive test names that explain the behavior
- Keep tests focused and independent
- Use setup blocks to reduce duplication

### Coverage Goals

- Aim for >80% test coverage
- All public functions must have tests
- Test edge cases and error conditions
- Don't test private functions directly

### Running Specific Tests

```bash
# Run tests matching a pattern
mix test --only focus

# Run failed tests
mix test --failed

# Run tests with specific tag
mix test --only integration
```

## Documentation Guidelines

### README Updates

- Keep installation instructions up-to-date
- Add examples for new features
- Update feature list
- Keep API reference current

### CHANGELOG Updates

- Add entries under `[Unreleased]` section
- Use categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Include ticket/issue numbers when relevant

Example:

```markdown
## [Unreleased]

### Added
- New `burst` send pattern for actor simulation (#123)

### Fixed
- Virtual clock race condition in concurrent scenarios (#124)
```

### Module Documentation

- Start with a brief one-line summary
- Provide a detailed explanation
- Include usage examples
- Document all options and callbacks

## Submitting Changes

### Before Submitting

1. **Run all checks:**
   ```bash
   ./scripts/prepare_release.sh
   ```

2. **Update documentation:**
   - Add/update module docs
   - Update README if needed
   - Add CHANGELOG entry

3. **Write/update tests:**
   - Add tests for new functionality
   - Update existing tests if behavior changed
   - Ensure all tests pass

### Pull Request Process

1. **Create a pull request:**
   - Use a clear, descriptive title
   - Fill out the PR template completely
   - Reference related issues

2. **PR title format:**
   - `feat: Add burst send pattern to actor simulation`
   - `fix: Resolve race condition in VirtualClock`
   - `docs: Update installation instructions`
   - `test: Add tests for edge cases in send_after`
   - `refactor: Simplify VirtualClock state management`
   - `perf: Optimize event queue processing`

3. **Review process:**
   - Address review comments promptly
   - Keep the PR updated with main branch
   - Be open to feedback and suggestions

4. **Merging:**
   - PRs require at least one approval
   - All CI checks must pass
   - Maintainers will merge approved PRs

### Commit Guidelines

- Use clear, descriptive commit messages
- Start with a verb in present tense (Add, Fix, Update, etc.)
- Reference issue numbers when applicable
- Keep commits focused and atomic

Good commit messages:
```
Add burst send pattern to ActorSimulation

Implement burst pattern that sends N messages every interval.
Useful for modeling bursty traffic patterns.

Fixes #123
```

```
Fix race condition in VirtualClock.advance/2

The advance function could race with scheduled events,
causing events to be processed out of order. This change
adds proper synchronization.

Related to #124
```

## Release Process

Maintainers handle releases, but understanding the process helps with contributions:

1. **Version bump:**
   ```bash
   ./scripts/bump_version.sh patch  # or minor, major
   ```

2. **Update CHANGELOG:**
   - Move unreleased items to new version section
   - Add release date
   - Review and organize entries

3. **Create release:**
   ```bash
   git push origin main
   git push origin --tags
   ```

4. **Verify:**
   - Check GitHub Actions workflows pass
   - Verify package on Hex.pm
   - Verify docs on HexDocs.pm

## Questions?

- **Chat:** Open a discussion on GitHub
- **Issues:** Open an issue for bugs or feature requests
- **Email:** Contact maintainers directly for sensitive issues

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions make this project better for everyone. Thank you for taking the time to contribute! 🎉

