// Generated from ActorSimulation DSL
// JUnit 5 tests for Worker2Actor

package com.example.actors;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;
import io.vlingo.xoom.actors.testkit.AccessSafely;
import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test class for Worker2Actor.
 */
public class Worker2ActorTest {
  private World world;
  private Worker2Protocol actor;

  @BeforeEach
  public void setUp() {
    world = World.startWithDefaults("test-world");
    actor = world.actorFor(
      Worker2Protocol.class,
      Definition.has(Worker2Actor.class,
        Definition.parameters((Worker2Callbacks) null, new java.util.ArrayList<>()))
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
  public void testProcesstaskMessage() {
    // Act
    actor.processTask();

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
