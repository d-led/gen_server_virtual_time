// Generated from ActorSimulation DSL
// Actor: subscriber1

use "collections"
use "time"

actor Subscriber1
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Subscriber1] = Array[Subscriber1]
  let logger: ConsoleLogger
  let _callbacks: Subscriber1Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Subscriber1] val = recover Array[Subscriber1] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Subscriber1CallbacksImpl(logger)




