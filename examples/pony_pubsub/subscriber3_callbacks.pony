// Generated from ActorSimulation DSL
// Callback trait for: subscriber3
//
// Implement this trait to add custom behavior!

trait Subscriber3Callbacks
  fun ref on_message()

class Subscriber3CallbacksImpl is Subscriber3Callbacks
  """
  Default implementation of Subscriber3 callbacks.
  
  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """
  
  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

