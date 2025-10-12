// Generated from ActorSimulation DSL
// Actor: processor

use "collections"
use "time"
use "processor_callbacks"


actor Processor
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Processor] = Array[Processor]
  let _callbacks: ProcessorCallbacks


  new create(env: Env, targets: Array[Processor] val = recover Array[Processor] end) =>
    _env = env
    _targets.append(targets)
    _callbacks = recover ProcessorCallbacksImpl end




