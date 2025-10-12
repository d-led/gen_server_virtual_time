// Generated from ActorSimulation DSL
// Callback trait for: stage2
//
// Implement this trait to add custom behavior!

trait Stage2Callbacks
  fun ref on_message()

class Stage2CallbacksImpl is Stage2Callbacks
  """
  Default implementation of Stage2 callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  fun ref on_message() =>
    // TODO: Implement custom behavior
    None

