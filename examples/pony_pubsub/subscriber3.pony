// Generated from ActorSimulation DSL
// Actor: subscriber3

use "collections"
use "time"
use "subscriber3_callbacks"


actor Subscriber3
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Subscriber3] = Array[Subscriber3]
  let _callbacks: Subscriber3Callbacks


  new create(env: Env, targets: Array[Subscriber3] val = recover Array[Subscriber3] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Subscriber3CallbacksImpl end




