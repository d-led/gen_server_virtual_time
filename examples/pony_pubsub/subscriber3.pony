// Generated from ActorSimulation DSL
// Actor: subscriber3

use "collections"
use "time"
use "console_logger"
use "subscriber3_callbacks"


actor Subscriber3
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Subscriber3] = Array[Subscriber3]
  let logger: ConsoleLogger
  let _callbacks: Subscriber3Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Subscriber3] val = recover Array[Subscriber3] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Subscriber3CallbacksImpl(logger)




