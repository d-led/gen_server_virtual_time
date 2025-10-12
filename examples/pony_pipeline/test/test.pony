// Generated from ActorSimulation DSL
// PonyTest tests for pipeline_actors

use "ponytest"
use "../console_logger"
use "..source"
use "..stage1"
use "..stage2"
use "..stage3"
use "..sink"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestActorSystem)
    test(_TestSource)
    test(_TestStage1)
    test(_TestStage2)
    test(_TestStage3)
    test(_TestSink)


class iso _TestActorSystem is UnitTest
  """Test that the actor system can be initialized."""

  fun name(): String => "Actor System"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    h.complete(true)

class iso _TestSource is UnitTest
  """Test that Source actor can be created."""

  fun name(): String => "Source actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Source(h.env, logger)
    h.complete(true)

class iso _TestStage1 is UnitTest
  """Test that Stage1 actor can be created."""

  fun name(): String => "Stage1 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Stage1(h.env, logger)
    h.complete(true)

class iso _TestStage2 is UnitTest
  """Test that Stage2 actor can be created."""

  fun name(): String => "Stage2 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Stage2(h.env, logger)
    h.complete(true)

class iso _TestStage3 is UnitTest
  """Test that Stage3 actor can be created."""

  fun name(): String => "Stage3 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Stage3(h.env, logger)
    h.complete(true)

class iso _TestSink is UnitTest
  """Test that Sink actor can be created."""

  fun name(): String => "Sink actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Sink(h.env, logger)
    h.complete(true)

