// Generated from ActorSimulation DSL
// Actor: server3

use "collections"
use "time"
use "server3_callbacks"


actor Server3
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Server3] = Array[Server3]
  let _callbacks: Server3Callbacks


  new create(env: Env, targets: Array[Server3] val = recover Array[Server3] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Server3CallbacksImpl end




