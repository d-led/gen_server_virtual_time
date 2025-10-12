// Generated from ActorSimulation DSL
// Actor: subscriber1

use "collections"
use "time"
use "subscriber1_callbacks"


actor Subscriber1
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Subscriber1] = Array[Subscriber1]
  let _callbacks: Subscriber1Callbacks


  new create(env: Env, targets: Array[Subscriber1] val = recover Array[Subscriber1] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover Subscriber1CallbacksImpl end




