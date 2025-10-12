// Generated from ActorSimulation DSL
// Callback trait for: burst_generator
//
// Implement this trait to add custom behavior!

trait BurstGeneratorCallbacks
  fun ref on_batch()

class BurstGeneratorCallbacksImpl is BurstGeneratorCallbacks
  """
  Default implementation of BurstGenerator callbacks.

  CUSTOMIZE THIS CLASS to add your own behavior!
  The generated actor code will call these methods.
  """

  fun ref on_batch() =>
    // TODO: Implement custom behavior for batch
    None

