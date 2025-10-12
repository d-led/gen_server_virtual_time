// Generated from ActorSimulation DSL
// Actor: stage2

use "collections"
use "time"

actor Stage2
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Stage2] = Array[Stage2]
  let logger: ConsoleLogger
  let _callbacks: Stage2Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Stage2] val = recover Array[Stage2] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Stage2CallbacksImpl(logger)




