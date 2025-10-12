// Generated from ActorSimulation DSL
// Callback trait for: server3
//
// Implement this trait to add custom behavior!

trait Server3Callbacks
  fun ref on_message()

class Server3CallbacksImpl is Server3Callbacks
  """
  Default implementation of Server3 callbacks.
  
  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """
  
  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

