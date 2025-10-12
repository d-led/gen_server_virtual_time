// Generated from ActorSimulation DSL
// Actor: publisher

use "collections"
use "time"
use "console_logger"
use "publisher_callbacks"


actor Publisher
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Publisher] = Array[Publisher]
  let logger: ConsoleLogger
  let _callbacks: PublisherCallbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Publisher] val = recover Array[Publisher] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = PublisherCallbacksImpl(logger)
    let timer = Timer(EventTimer(this), 100000000, 100000000)
    _timers(consume timer)


  be event() =>
  _callbacks.on_event()
    // Send to targets
    for target in _targets.values() do
      target.event()
    end

class EventTimer is TimerNotify
  let _actor: Publisher tag

  new iso create(actor': Publisher) =>
    _actor = actor'

  fun ref apply(timer: Timer, count: U64): Bool =>
    _actor.event()
    true  // Keep timer running

