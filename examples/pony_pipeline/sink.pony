// Generated from ActorSimulation DSL
// Actor: sink

use "collections"
use "time"
use "console_logger"
use "sink_callbacks"


actor Sink
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Sink] = Array[Sink]
  let logger: ConsoleLogger
  let _callbacks: SinkCallbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Sink] val = recover Array[Sink] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = SinkCallbacksImpl(logger)




