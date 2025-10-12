// Generated from ActorSimulation DSL
// Actor: database

use "collections"
use "time"

actor Database
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Database] = Array[Database]
  let logger: ConsoleLogger
  let _callbacks: DatabaseCallbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Database] val = recover Array[Database] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = DatabaseCallbacksImpl(logger)




