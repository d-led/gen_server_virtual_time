// Generated from ActorSimulation DSL
// Actor: stage1

use "collections"
use "time"
use "stage1_callbacks"


actor Stage1
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Stage1] = Array[Stage1]
  let _callbacks: Stage1Callbacks


  new create(env: Env, targets: Array[Stage1] val = recover Array[Stage1] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Stage1CallbacksImpl end




