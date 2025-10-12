// Generated from ActorSimulation DSL
// Actor: stage2

use "collections"
use "time"
use "stage2_callbacks"


actor Stage2
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Stage2] = Array[Stage2]
  let _callbacks: Stage2Callbacks


  new create(env: Env, targets: Array[Stage2] val = recover Array[Stage2] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Stage2CallbacksImpl end




