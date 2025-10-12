// Generated from ActorSimulation DSL
// Callback trait for: sink
//
// Implement this trait to add custom behavior!

trait SinkCallbacks
  fun ref on_message()

class SinkCallbacksImpl is SinkCallbacks
  """
  Default implementation of Sink callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

