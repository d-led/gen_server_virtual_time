// Generated from ActorSimulation DSL
// Actor: burst_generator

use "collections"
use "time"
use "console_logger"
use "burst_generator_callbacks"


actor BurstGenerator
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[BurstGenerator] = Array[BurstGenerator]
  let logger: ConsoleLogger
  let _callbacks: BurstGeneratorCallbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[BurstGenerator] val = recover Array[BurstGenerator] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = BurstGeneratorCallbacksImpl(logger)
    let timer = Timer(BatchBurstTimer(this, 10), 1000000000, 1000000000)
    _timers(consume timer)


  be batch() =>
  _callbacks.on_batch()
    // Send to targets
    for target in _targets.values() do
      target.batch()
    end

class BatchBurstTimer is TimerNotify
  let _actor: BurstGenerator tag
  let _burst_count: USize

  new iso create(actor': BurstGenerator, burst_count: USize) =>
    _actor = actor'
    _burst_count = burst_count

  fun ref apply(timer: Timer, count: U64): Bool =>
    var i: USize = 0
    while i < _burst_count do
      _actor.batch()
      i = i + 1
    end
    true  // Keep timer running

