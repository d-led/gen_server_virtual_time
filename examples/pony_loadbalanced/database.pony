// Generated from ActorSimulation DSL
// Actor: database

use "collections"
use "time"
use "database_callbacks"


actor Database
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Database] = Array[Database]
  let _callbacks: DatabaseCallbacks


  new create(env: Env, targets: Array[Database] val = recover Array[Database] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover DatabaseCallbacksImpl end




