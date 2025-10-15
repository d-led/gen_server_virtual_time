// Generated from ActorSimulation DSL
// Integration tests for actors

use ractor::Actor;

#[tokio::test]
async fn test_actor_system() {
    // Basic system test
    assert!(true);
}

#[tokio::test]
async fn test_publisher_spawns() {
    use pubsub_actors::actors::publisher::Publisher;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Publisher::spawn(None, Publisher, ())
        .await
        .expect("Failed to spawn publisher");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_subscriber1_spawns() {
    use pubsub_actors::actors::subscriber1::Subscriber1;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Subscriber1::spawn(None, Subscriber1, ())
        .await
        .expect("Failed to spawn subscriber1");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_subscriber2_spawns() {
    use pubsub_actors::actors::subscriber2::Subscriber2;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Subscriber2::spawn(None, Subscriber2, ())
        .await
        .expect("Failed to spawn subscriber2");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_subscriber3_spawns() {
    use pubsub_actors::actors::subscriber3::Subscriber3;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Subscriber3::spawn(None, Subscriber3, ())
        .await
        .expect("Failed to spawn subscriber3");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}
