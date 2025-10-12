// Generated from ActorSimulation DSL
// Callback trait for: server2
//
// Implement this trait to add custom behavior!

use "console_logger"

trait Server2Callbacks
  fun ref on_message()

class Server2CallbacksImpl is Server2Callbacks
  """
  Default implementation of Server2 callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  let _logger: ConsoleLogger

  new create(logger: ConsoleLogger) =>
    _logger = logger

  fun ref on_message() =>
    // TODO: Implement custom behavior
    _logger.log("Server2: Processing message")

