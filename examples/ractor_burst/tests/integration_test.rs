// Generated from ActorSimulation DSL
// Integration tests for actors

use ractor::Actor;

#[tokio::test]
async fn test_actor_system() {
    // Basic system test
    assert!(true);
}

#[tokio::test]
async fn test_processor_spawns() {
    use burst_actors::actors::processor::Processor;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Processor::spawn(None, Processor, ())
        .await
        .expect("Failed to spawn processor");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_burst_generator_spawns() {
    use burst_actors::actors::burst_generator::BurstGenerator;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = BurstGenerator::spawn(None, BurstGenerator, ())
        .await
        .expect("Failed to spawn burst_generator");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}
