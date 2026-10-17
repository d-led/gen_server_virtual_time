// Generated from ActorSimulation DSL
// JUnit 5 tests for LoadBalancerActor

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
 * Test class for LoadBalancerActor. The time the actor waits in is this test's:
 * the scheduler it is handed is a ManualScheduler, so nothing is due until the
 * test says how much time has passed.
 */
public class LoadBalancerActorTest {
  private static final long INTERVAL_MILLIS = 50L;
  private static final long BOUND_MILLIS = 1000L;
      private static final int REPEATS = 3;

  private World world;
  private ManualScheduler clock;
  private LoadBalancerProtocol actor;
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

    final LoadBalancerCallbacks counting = new LoadBalancerCallbacks() {
      @Override
      public void onDistributeWork() {
        count();
      }

    };

    actor =
        world.actorFor(
            LoadBalancerProtocol.class,
            Definition.has(
                LoadBalancerActor.class,
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
  public void testTheActorSendsOncePerIntervalTheTestSaysHasPassed() {
    // The actor arms its timer in its constructor, which runs when its first
    // message is handled: the test waits for that delivery, and for no time.
    handled.resetHappeningsTo(1);
    actor.distributeWork();
    assertTrue(
        handled.completesWithin(BOUND_MILLIS), "the actor did not handle its first message");

    final int before = sent.get();

    clock.advanceBy(INTERVAL_MILLIS - 1);
    assertEquals(before, sent.get(), "the actor sent before its interval was up");

    handled.resetHappeningsTo(REPEATS);
    clock.advanceBy(REPEATS * INTERVAL_MILLIS);
    assertTrue(
        handled.completesWithin(BOUND_MILLIS), "the sends the clock made due were not handled");
    assertEquals(
        before + REPEATS,
        sent.get(),
        "one interval, one send: " + REPEATS + " intervals, " + REPEATS + " sends");
    }
}
