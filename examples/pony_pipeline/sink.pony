// Generated from ActorSimulation DSL
// Actor: sink

use "collections"
use "time"
use "sink_callbacks"


actor Sink
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Sink] = Array[Sink]
  let _callbacks: SinkCallbacks


  new create(env: Env, targets: Array[Sink] val = recover Array[Sink] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover SinkCallbacksImpl end




