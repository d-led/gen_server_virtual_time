# GenServer Callbacks Support Status

## Current Implementation Review

### Supported Callbacks

| Callback | Supported? | Virtual Time? | Notes |
|----------|-----------|---------------|-------|
| `init/1` | ✅ Yes | N/A | Fully supported in Wrapper |
| `handle_call/3` | ✅ Yes | ⚠️ Partial | Works but timeout not virtualized |
| `handle_cast/2` | ✅ Yes | ✅ Yes | Fully supported |
| `handle_info/2` | ✅ Yes | ✅ Yes | Fully supported |
| `handle_continue/2` | ❌ No | - | Not implemented |
| `terminate/2` | ⚠️ Partial | N/A | Delegates but not tested |
| `code_change/3` | ⚠️ Partial | N/A | Delegates but not tested |
| `format_status/2` | ❌ No | - | Not implemented |

### Timeouts

| Timeout Type | Supported? | Virtual Time? |
|--------------|-----------|---------------|
| `send_after/3` | ✅ Yes | ✅ Yes | Via `VirtualTimeGenServer.send_after` |
| `send_after_self/2` | ✅ Yes | ✅ Yes | Convenience wrapper |
| `GenServer.call/3` timeout | ❌ No | ❌ No | Uses real time |
| `:timeout` in init | ❌ No | ❌ No | Not virtualized |
| `{:timeout, ms, msg}` | ❌ No | ❌ No | Not implemented |

### Immediate Sends

| Feature | Supported? | Notes |
|---------|-----------|-------|
| `send/2` | ✅ Yes | Standard Erlang, always works |
| `Process.send/3` | ✅ Yes | Standard Erlang |
| `GenServer.call/2,3` | ✅ Yes | Synchronous RPC |
| `GenServer.cast/2` | ✅ Yes | Asynchronous |
| `send_after/3` (delay=0) | ✅ Yes | Immediate via virtual clock |

## Priority Fixes Needed

### High Priority
1. ❗ **Virtualize `GenServer.call/3` timeout** - Critical for testing
2. ❗ **Support `:timeout` in init return** - Common pattern
3. ❗ **Implement `handle_continue/2`** - OTP 21+ standard

### Medium Priority
4. ⚠️ **Test `terminate/2`** - Ensure cleanup works
5. ⚠️ **Test `code_change/3`** - Hot code reloading

### Low Priority
6. 💡 **Implement `format_status/2`** - Debugging aid

## Test Coverage Gaps

- [ ] `GenServer.call` with timeout in virtual time
- [ ] Init returning `{:ok, state, timeout}`
- [ ] Init returning `{:ok, state, {:continue, ...}}`
- [ ] `handle_continue/2` callback
- [ ] `terminate/2` being called
- [ ] `code_change/3` hot reload

## Next Steps

1. Add test for GenServer.call timeout virtualization
2. Implement timeout support in VirtualClock
3. Add handle_continue support
4. Document what works vs. what doesn't

