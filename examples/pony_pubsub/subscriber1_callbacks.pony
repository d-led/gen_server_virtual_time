// Generated from ActorSimulation DSL
// Callback trait for: subscriber1
//
// Implement this trait to add custom behavior!

trait Subscriber1Callbacks
  fun ref on_message()

class Subscriber1CallbacksImpl is Subscriber1Callbacks
  """
  Default implementation of Subscriber1 callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

