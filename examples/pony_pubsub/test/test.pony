// Generated from ActorSimulation DSL
// PonyTest tests for pubsub_actors

use "ponytest"
use "..publisher"
use "..subscriber1"
use "..subscriber2"
use "..subscriber3"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestActorSystem)
    test(_TestPublisher)
    test(_TestSubscriber1)
    test(_TestSubscriber2)
    test(_TestSubscriber3)


class iso _TestActorSystem is UnitTest
  """Test that the actor system can be initialized."""
  
  fun name(): String => "Actor System"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    h.complete(true)

class iso _TestPublisher is UnitTest
  """Test that Publisher actor can be created."""
  
  fun name(): String => "Publisher actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let _actor = Publisher(h.env)
    h.complete(true)

class iso _TestSubscriber1 is UnitTest
  """Test that Subscriber1 actor can be created."""
  
  fun name(): String => "Subscriber1 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let _actor = Subscriber1(h.env)
    h.complete(true)

class iso _TestSubscriber2 is UnitTest
  """Test that Subscriber2 actor can be created."""
  
  fun name(): String => "Subscriber2 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let _actor = Subscriber2(h.env)
    h.complete(true)

class iso _TestSubscriber3 is UnitTest
  """Test that Subscriber3 actor can be created."""
  
  fun name(): String => "Subscriber3 actor"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)  // 2 second timeout
    // Actor creation test
    let _actor = Subscriber3(h.env)
    h.complete(true)

