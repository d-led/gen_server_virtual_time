// Generated from ActorSimulation DSL
// JUnit 5 tests for ConsumerActor

package com.example.actors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;
import io.vlingo.xoom.actors.testkit.TestUntil;
import java.util.ArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Test class for ConsumerActor.
 */
public class ConsumerActorTest {
  private static final long BOUND_MILLIS = 1000L;

  private World world;
  private ConsumerProtocol actor;
  private final AtomicInteger sent = new AtomicInteger();
  private final TestUntil handled = TestUntil.happenings(1);

  private void count() {
    sent.incrementAndGet();
    handled.happened();
  }

  @BeforeEach
  public void setUp() {
    world = World.startWithDefaults("test-world");

    final ConsumerCallbacks counting = new ConsumerCallbacks() {
      @Override
      public void onProcess() {
        count();
      }

    };

    actor =
        world.actorFor(
            ConsumerProtocol.class,
            Definition.has(
                ConsumerActor.class, Definition.parameters(counting)));
  }

  @AfterEach
  public void tearDown() {
    if (world != null) {
      world.terminate();
    }
  }

  @Test
  public void testActorCreation() {
    assertNotNull(actor, "Actor should be created");
  }

  @Test
  public void testTheActorHandlesItsMessage() {
    handled.resetHappeningsTo(1);
    actor.process();
    assertTrue(handled.completesWithin(BOUND_MILLIS), "the actor did not handle the message");
    assertEquals(1, sent.get(), "the actor handled the message once");
  }
}
