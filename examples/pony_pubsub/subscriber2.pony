// Generated from ActorSimulation DSL
// Actor: subscriber2

use "collections"
use "time"
use "subscriber2_callbacks"


actor Subscriber2
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Subscriber2] = Array[Subscriber2]
  let _callbacks: Subscriber2Callbacks


  new create(env: Env, targets: Array[Subscriber2] val = recover Array[Subscriber2] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Subscriber2CallbacksImpl end




