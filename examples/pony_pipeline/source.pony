// Generated from ActorSimulation DSL
// Actor: source

use "collections"
use "time"
use "source_callbacks"


actor Source
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Source] = Array[Source]
  let _callbacks: SourceCallbacks


  new create(env: Env, targets: Array[Source] val = recover Array[Source] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover SourceCallbacksImpl end
let timer = Timer(DataTimer(this), 0.02 as U64 * 1_000_000_000, 0.02 as U64 * 1_000_000_000)
    _timers(consume timer)


  be data() =>
  _callbacks.on_data()
    // Send to targets
    for target in _targets.values() do
      target.data()
    end

class DataTimer is TimerNotify
  let _actor: Source tag

  new iso create(actor: Source tag) =>
    _actor = actor

  fun ref apply(timer: Timer, count: U64): Bool =>
    _actor.data()
    true  // Keep timer running

