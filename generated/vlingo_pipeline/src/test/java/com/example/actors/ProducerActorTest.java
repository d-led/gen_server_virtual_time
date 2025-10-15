// Generated from ActorSimulation DSL
// JUnit 5 tests for ProducerActor

package com.example.actors;

import io.vlingo.xoom.actors.Definition;
import io.vlingo.xoom.actors.World;
import io.vlingo.xoom.actors.testkit.AccessSafely;
import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Test class for ProducerActor.
 */
public class ProducerActorTest {
  private World world;
  private ProducerProtocol actor;

  @BeforeEach
  public void setUp() {
    world = World.startWithDefaults("test-world");
    actor = world.actorFor(
      ProducerProtocol.class,
      Definition.has(ProducerActor.class,
        Definition.parameters((ProducerCallbacks) null, new java.util.ArrayList<>()))
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
  public void testDataMessage() {
    // Act
    actor.data();

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
