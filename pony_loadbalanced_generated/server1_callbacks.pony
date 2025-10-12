// Generated from ActorSimulation DSL
// Callback trait for: server1
//
// Implement this trait to add custom behavior!

trait Server1Callbacks
  fun ref on_message()

class Server1CallbacksImpl is Server1Callbacks
  """
  Default implementation of Server1 callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

