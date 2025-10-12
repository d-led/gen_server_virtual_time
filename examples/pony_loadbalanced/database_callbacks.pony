// Generated from ActorSimulation DSL
// Callback trait for: database
//
// Implement this trait to add custom behavior!

trait DatabaseCallbacks
  fun ref on_message()

class DatabaseCallbacksImpl is DatabaseCallbacks
  """
  Default implementation of Database callbacks.
  
  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """
  
  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

