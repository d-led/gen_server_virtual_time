// Generated from ActorSimulation DSL
// Callback trait for: stage1
//
// Implement this trait to add custom behavior!

trait Stage1Callbacks
  fun ref on_message()

class Stage1CallbacksImpl is Stage1Callbacks
  """
  Default implementation of Stage1 callbacks.
  
  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """
  
  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

