// Generated from ActorSimulation DSL
// JUnit 5 tests for Worker3Actor

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
 * Test class for Worker3Actor. The time the actor waits in is this test's:
 * the scheduler it is handed is a ManualScheduler, so nothing is due until the
 * test says how much time has passed.
 */
public class Worker3ActorTest {
  private static final long INTERVAL_MILLIS = 200L;
  private static final long BOUND_MILLIS = 1000L;

  private World world;
  private ManualScheduler clock;
  private Worker3Protocol actor;
  private final AtomicInteger sent = new AtomicInteger();
  private final TestUntil handled = TestUntil.happenings(1);

  private void count() {
    sent.incrementAndGet();
    handled.happened();
  }

  @BeforeEach
  public void setUp() {
    clock = new ManualScheduler();
    world = World.startWithDefaults("test-world");

    final Worker3Callbacks counting = new Worker3Callbacks() {
      @Override
      public void onProcessTask() {
        count();
      }

    };

    actor =
        world.actorFor(
            Worker3Protocol.class,
            Definition.has(
                Worker3Actor.class,
                Definition.parameters(counting, new ArrayList<>(), clock)));
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
  public void testTheActorSendsWhenTheTestSaysItsIntervalHasPassed() {
    // The actor arms its timer in its constructor, which runs when its first
    // message is handled: the test waits for that delivery, and for no time.
    handled.resetHappeningsTo(1);
    actor.processTask();
    assertTrue(
        handled.completesWithin(BOUND_MILLIS), "the actor did not handle its first message");

    final int before = sent.get();

    clock.advanceBy(INTERVAL_MILLIS - 1);
    assertEquals(before, sent.get(), "the actor sent before its interval was up");

    handled.resetHappeningsTo(1);
    clock.advanceBy(1);
    assertTrue(
        handled.completesWithin(BOUND_MILLIS), "the send the clock made due was not handled");
    assertEquals(before + 1, sent.get(), "the actor did not send when its interval was up");
  }
}
