// Generated from ActorSimulation DSL
// Actor: stage3

use "collections"
use "time"

actor Stage3
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Stage3] = Array[Stage3]
  let logger: ConsoleLogger
  let _callbacks: Stage3Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Stage3] val = recover Array[Stage3] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Stage3CallbacksImpl(logger)




