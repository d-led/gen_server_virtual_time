// Generated from ActorSimulation DSL
// Actor: server3

use "collections"
use "time"
use "console_logger"
use "server3_callbacks"


actor Server3
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Server3] = Array[Server3]
  let logger: ConsoleLogger
  let _callbacks: Server3Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Server3] val = recover Array[Server3] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Server3CallbacksImpl(logger)




