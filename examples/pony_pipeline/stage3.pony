// Generated from ActorSimulation DSL
// Actor: stage3

use "collections"
use "time"
use "stage3_callbacks"


actor Stage3
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Stage3] = Array[Stage3]
  let _callbacks: Stage3Callbacks


  new create(env: Env, targets: Array[Stage3] val = recover Array[Stage3] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Stage3CallbacksImpl end




