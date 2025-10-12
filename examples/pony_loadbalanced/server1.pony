// Generated from ActorSimulation DSL
// Actor: server1

use "collections"
use "time"

actor Server1
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Server1] = Array[Server1]
  let logger: ConsoleLogger
  let _callbacks: Server1Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Server1] val = recover Array[Server1] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Server1CallbacksImpl(logger)




