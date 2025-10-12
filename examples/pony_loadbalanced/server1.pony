// Generated from ActorSimulation DSL
// Actor: server1

use "collections"
use "time"
use "server1_callbacks"


actor Server1
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Server1] = Array[Server1]
  let _callbacks: Server1Callbacks


  new create(env: Env, targets: Array[Server1] val = recover Array[Server1] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Server1CallbacksImpl end




