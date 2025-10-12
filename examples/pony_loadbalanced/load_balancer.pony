// Generated from ActorSimulation DSL
// Actor: load_balancer

use "collections"
use "time"
use "console_logger"
use "load_balancer_callbacks"


actor LoadBalancer
  let _env: Env
  let _timers: Timers = Timers
  let _targets: Array[LoadBalancer] = Array[LoadBalancer]
  let logger: ConsoleLogger
  let _callbacks: LoadBalancerCallbacks


  new create(env: Env, logger': ConsoleLogger, targets: Array[LoadBalancer] val = recover Array[LoadBalancer] end) =>
    _env = env
    logger = logger'
    _targets.append(targets)
    _callbacks = LoadBalancerCallbacksImpl(logger)
let timer = Timer(RequestTimer(this), 0.01 as U64 * 1_000_000_000, 0.01 as U64 * 1_000_000_000)
    _timers(consume timer)


  be request() =>
  _callbacks.on_request()
    // Send to targets
    for target in _targets.values() do
      target.request()
    end

class RequestTimer is TimerNotify
  let _actor: LoadBalancer tag

  new iso create(actor: LoadBalancer tag) =>
    _actor = actor

  fun ref apply(timer: Timer, count: U64): Bool =>
    _actor.request()
    true  // Keep timer running

