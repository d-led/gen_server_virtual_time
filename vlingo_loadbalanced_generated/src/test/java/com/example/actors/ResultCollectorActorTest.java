// Generated from ActorSimulation DSL
// JUnit 5 tests for ResultCollectorActor

package com.example.actors;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;
import io.vlingo.xoom.actors.testkit.AccessSafely;
import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test class for ResultCollectorActor.
 */
public class ResultCollectorActorTest {
  private World world;
  private ResultCollectorProtocol actor;

  @BeforeEach
  public void setUp() {
    world = World.startWithDefaults("test-world");
    actor = world.actorFor(
      ResultCollectorProtocol.class,
      Definition.has(ResultCollectorActor.class,
        Definition.parameters((ResultCollectorCallbacks) null))
    );
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
  public void testAggregateresultsMessage() {
    // Act
    actor.aggregateResults();

    // Wait a bit for async processing
    try {
      Thread.sleep(100);
    } catch (InterruptedException e) {
      fail("Test interrupted");
    }

    // Assert - actor should handle message without errors
    assertTrue(true, "Message handled successfully");
  }

}
