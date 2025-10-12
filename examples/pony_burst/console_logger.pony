// Generated from ActorSimulation DSL
// Thread-safe console logger actor
//
// Based on best practices from Pony actor systems
// See: https://github.com/d-led/DDDwithActorsPony/blob/master/Receiver.pony

actor ConsoleLogger
  """
  Thread-safe console logger that uses env.out for output.
  All logging goes through this actor to avoid race conditions.
  """

  let _out: OutStream

  new create(out: OutStream) =>
    _out = out

  be log(msg: String) =>
    """
    Log a message to console.
    This is thread-safe as it's processed sequentially by the actor.
    """
    _out.print(msg)
