// Generated from ActorSimulation DSL
// PonyTest tests for loadbalanced_actors

use "ponytest"
use "../console_logger"
use "..load_balancer"
use "..server1"
use "..server2"
use "..server3"
use "..database"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestActorSystem)
    test(_TestLoadBalancer)
    test(_TestServer1)
    test(_TestServer2)
    test(_TestServer3)
    test(_TestDatabase)


class iso _TestActorSystem is UnitTest
  """Test that the actor system can be initialized."""

  fun name(): String => "Actor System"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    h.complete(true)

class iso _TestLoadBalancer is UnitTest
  """Test that LoadBalancer actor can be created."""

  fun name(): String => "LoadBalancer actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = LoadBalancer(h.env, logger)
    h.complete(true)

class iso _TestServer1 is UnitTest
  """Test that Server1 actor can be created."""

  fun name(): String => "Server1 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Server1(h.env, logger)
    h.complete(true)

class iso _TestServer2 is UnitTest
  """Test that Server2 actor can be created."""

  fun name(): String => "Server2 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Server2(h.env, logger)
    h.complete(true)

class iso _TestServer3 is UnitTest
  """Test that Server3 actor can be created."""

  fun name(): String => "Server3 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Server3(h.env, logger)
    h.complete(true)

class iso _TestDatabase is UnitTest
  """Test that Database actor can be created."""

  fun name(): String => "Database actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let logger = ConsoleLogger(h.env.out)
    let _actor = Database(h.env, logger)
    h.complete(true)

