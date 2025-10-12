// Generated from ActorSimulation DSL
// PonyTest tests for burst_actors

use "ponytest"
use "..processor"
use "..burst_generator"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestActorSystem)
    test(_TestProcessor)
    test(_TestBurstGenerator)


class iso _TestActorSystem is UnitTest
  """Test that the actor system can be initialized."""

  fun name(): String => "Actor System"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    h.complete(true)

class iso _TestProcessor is UnitTest
  """Test that Processor actor can be created."""

  fun name(): String => "Processor actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let _actor = Processor(h.env)
    h.complete(true)

class iso _TestBurstGenerator is UnitTest
  """Test that BurstGenerator actor can be created."""

  fun name(): String => "BurstGenerator actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let _actor = BurstGenerator(h.env)
    h.complete(true)

