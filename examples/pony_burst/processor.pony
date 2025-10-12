// Generated from ActorSimulation DSL
// Actor: processor

use "collections"
use "time"

actor Processor
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[Processor] = Array[Processor]
  let logger: ConsoleLogger
  let _callbacks: ProcessorCallbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[Processor] val = recover Array[Processor] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = ProcessorCallbacksImpl(logger)




