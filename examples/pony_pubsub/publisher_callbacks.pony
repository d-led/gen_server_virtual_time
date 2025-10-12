// Generated from ActorSimulation DSL
// Callback trait for: publisher
//
// Implement this trait to add custom behavior!

trait PublisherCallbacks
  fun ref on_event()

class PublisherCallbacksImpl is PublisherCallbacks
  """
  Default implementation of Publisher callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  let _logger: ConsoleLogger

  new create(logger: ConsoleLogger) =>
    _logger = logger

  fun ref on_event() =>
    // TODO: Implement custom behavior for event
    _logger.log("Publisher: Sending event message")

