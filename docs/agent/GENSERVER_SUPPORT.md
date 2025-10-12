# GenServer Callback Support Status

**Status as of**: 2025-10-12  
**Package Version**: 0.2.x  
**All Tests**: ✅ 92 passing, 0 failures

---

## ✅ Fully Supported

### Core Callbacks

- **`init/1`** - ✅ Works with virtual time
- **`handle_call/3`** - ✅ Synchronous RPC works
- **`handle_cast/2`** - ✅ Async messages work
- **`handle_info/2`** - ✅ All message types work
- **`terminate/2`** - ✅ Cleanup works
- **`code_change/3`** - ✅ Hot reload supported

### Time Operations

- **`VirtualTimeGenServer.send_after/3`** - ✅ Virtual time delays
- **`VirtualTimeGenServer.send_after_self/2`** - ✅ Convenience wrapper
- **`send/2`** - ✅ Immediate sends (standard Erlang)
- **`GenServer.call/2,3`** - ✅ Synchronous calls work
- **`GenServer.cast/2`** - ✅ Async casts work

---

## ⚠️ Partial Support

### Timeouts

- **`GenServer.call/3` timeout** - ⚠️ Uses real time, not virtual
- **`:timeout` in init** - ⚠️ Not virtualized yet
- **`{:timeout, ms, msg}`** - ⚠️ Not implemented

### OTP 21+ Features

- **`handle_continue/2`** - ❌ Not implemented yet

---

## 📊 Test Coverage

| Feature             | Tests | Status           |
| ------------------- | ----- | ---------------- |
| Basic GenServer     | ✅    | 100%             |
| handle_call         | ✅    | Multiple tests   |
| handle_cast         | ✅    | Tested           |
| handle_info         | ✅    | Comprehensive    |
| send_after          | ✅    | Virtual time     |
| Immediate sends     | ✅    | Tested           |
| Combined callbacks  | ✅    | Integration test |
| Actor simulation    | ✅    | 33 tests         |
| Dining philosophers | ✅    | 7 tests          |
| Diagram generation  | ✅    | 7 tests          |

---

## 🎯 Roadmap

### High Priority

1. ❗ **Virtualize GenServer.call timeout** - Critical for testing timeouts
2. ❗ **Speed up test suite** - Currently 12.3s, target < 5s
3. ❗ **Implement handle_continue/2** - OTP 21+ standard

### Medium Priority

4. ⚠️ **Support :timeout in init** - Common pattern
5. ⚠️ **GenServer.multi_call support** - Distributed systems
6. ⚠️ **Better timeout handling** - {:timeout, ms, msg} tuples

### Low Priority

7. 💡 **format_status/2** - Debugging aid
8. 💡 **Process hibernation** - Memory optimization
9. 💡 **Custom timeout backend** - Pluggable time sources

---

## 💡 Usage Patterns

### Basic GenServer with Virtual Time

```elixir
defmodule MyServer do
  use VirtualTimeGenServer

  def init(state) do
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Schedule next work in virtual time
    VirtualTimeGenServer.send_after(self(), :work, 1000)
    {:noreply, state}
  end
end

# In tests
{:ok, clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(clock)
{:ok, server} = MyServer.start_link(%{})

# Advance virtual time instantly
VirtualClock.advance(clock, 1000)
```

### Synchronous Calls (handle_call)

```elixir
def handle_call(:get_status, _from, state) do
  {:reply, state.status, state}
end

# Works normally
GenServer.call(server, :get_status)
```

### Async Casts (handle_cast)

```elixir
def handle_cast(:increment, state) do
  {:noreply, %{state | count: state.count + 1}}
end

# Works normally
GenServer.cast(server, :increment)
```

### Immediate Messages

```elixir
# All these work:
send(server, :immediate)
Process.send(server, :message, [])
GenServer.call(server, :sync_request)
GenServer.cast(server, :async_request)
```

---

## ⚡ Performance

### Test Execution Times

- **VirtualTimeGenServer tests**: ~0.2s (8 tests)
- **Actor simulation tests**: ~12.0s (33 tests) ⚠️ SLOW
- **Diagram generation**: ~0.1s (7 tests)
- **Total**: ~12.3s (92 tests)

### Speed Optimization Targets

- ✅ Unit tests: < 0.5s total
- ⚠️ Integration tests: Should be < 2s (currently 12s)
- ✅ Diagram generation: < 0.5s total

**Issue**: Long simulations (1 hour virtual time) take too long in real time.
Need to optimize VirtualClock event processing.

---

## 🔧 Known Limitations

1. **GenServer.call timeout uses real time** - Can't test timeout logic with
   virtual time yet
2. **Long simulations are slow** - 1 hour virtual time takes several seconds
   real time
3. **handle_continue not supported** - OTP 21+ feature not implemented
4. **Process hibernation** - Not tested with virtual time

---

## 📝 Notes

- **Backward Compatible**: All changes are additive, no breaking changes
- **Production Ready**: Core features are stable and tested
- **Actor DSL**: Separate from GenServer, works alongside it
- **Diagram Generation**: Self-contained HTML files with Mermaid

---

_For the latest updates, see test suite and CHANGELOG.md_
