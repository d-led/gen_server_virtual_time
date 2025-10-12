// Generated from ActorSimulation DSL
// Callback trait for: processor
//
// Implement this trait to add custom behavior!

trait ProcessorCallbacks
  fun ref on_message()

class ProcessorCallbacksImpl is ProcessorCallbacks
  """
  Default implementation of Processor callbacks.
  
  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """
  
  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

