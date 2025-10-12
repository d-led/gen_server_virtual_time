// Generated from ActorSimulation DSL
// Callback trait for: subscriber2
//
// Implement this trait to add custom behavior!

use "console_logger"

trait Subscriber2Callbacks
  fun ref on_message()

class Subscriber2CallbacksImpl is Subscriber2Callbacks
  """
  Default implementation of Subscriber2 callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  let _logger: ConsoleLogger

  new create(logger: ConsoleLogger) =>
    _logger = logger

  fun ref on_message() =>
    // TODO: Implement custom behavior
    _logger.log("Subscriber2: Processing message")

