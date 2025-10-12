// Generated from ActorSimulation DSL
// Actor: load_balancer

use "collections"
use "time"

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
    let timer = Timer(RequestTimer(this), 10000000, 10000000)
    _timers(consume timer)


  be request() =>
  _callbacks.on_request()
    // Send to targets
    for target in _targets.values() do
      target.request()
    end

class RequestTimer is TimerNotify
  let _actor: LoadBalancer tag

  new iso create(actor': LoadBalancer) =>
    _actor = actor'

  fun ref apply(timer: Timer, count: U64): Bool =>
    _actor.request()
    true  // Keep timer running

