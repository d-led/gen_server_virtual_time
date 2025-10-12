// Generated from ActorSimulation DSL
// Actor: stage1

use "collections"
use "time"
use "console_logger"
use "stage1_callbacks"


actor Stage1
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Stage1] = Array[Stage1]
  let logger: ConsoleLogger
  let _callbacks: Stage1Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Stage1] val = recover Array[Stage1] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Stage1CallbacksImpl(logger)




