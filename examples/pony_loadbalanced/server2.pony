// Generated from ActorSimulation DSL
// Actor: server2

use "collections"
use "time"

actor Server2
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Server2] = Array[Server2]
  let logger: ConsoleLogger
  let _callbacks: Server2Callbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Server2] val = recover Array[Server2] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = Server2CallbacksImpl(logger)




