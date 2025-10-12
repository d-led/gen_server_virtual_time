// Generated from ActorSimulation DSL
// Actor: server2

use "collections"
use "time"
use "server2_callbacks"


actor Server2
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Server2] = Array[Server2]
  let _callbacks: Server2Callbacks


  new create(env: Env, targets: Array[Server2] val = recover Array[Server2] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Server2CallbacksImpl end




