// Generated from ActorSimulation DSL
// Callback trait for: source
//
// Implement this trait to add custom behavior!

trait SourceCallbacks
  fun ref on_data()

class SourceCallbacksImpl is SourceCallbacks
  """
  Default implementation of Source callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  let _logger: ConsoleLogger

  new create(logger: ConsoleLogger) =>
    _logger = logger

  fun ref on_data() =>
    // TODO: Implement custom behavior for data
    _logger.log("Source: Sending data message")

