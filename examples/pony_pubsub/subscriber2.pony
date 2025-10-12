// Generated from ActorSimulation DSL
// Actor: subscriber2

use "collections"
use "time"

actor Subscriber2
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Subscriber2] = Array[Subscriber2]
  let logger: ConsoleLogger
  let _callbacks: Subscriber2Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Subscriber2] val = recover Array[Subscriber2] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Subscriber2CallbacksImpl(logger)




