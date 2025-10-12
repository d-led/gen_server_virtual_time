// Generated from ActorSimulation DSL
// Callback trait for: load_balancer
//
// Implement this trait to add custom behavior!

use "console_logger"

trait LoadBalancerCallbacks
  fun ref on_request()

class LoadBalancerCallbacksImpl is LoadBalancerCallbacks
  """
  Default implementation of LoadBalancer callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  let _logger: ConsoleLogger

  new create(logger: ConsoleLogger) =>
    _logger = logger

  fun ref on_request() =>
    // TODO: Implement custom behavior for request
    _logger.log("LoadBalancer: Received request message")

