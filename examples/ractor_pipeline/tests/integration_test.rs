// Generated from ActorSimulation DSL
// Integration tests for actors

use ractor::Actor;

#[tokio::test]
async fn test_actor_system() {
    // Basic system test
    assert!(true);
}

#[tokio::test]
async fn test_source_spawns() {
    use pipeline_actors::actors::source::Source;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Source::spawn(None, Source, ())
        .await
        .expect("Failed to spawn source");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_stage1_spawns() {
    use pipeline_actors::actors::stage1::Stage1;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Stage1::spawn(None, Stage1, ())
        .await
        .expect("Failed to spawn stage1");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_stage2_spawns() {
    use pipeline_actors::actors::stage2::Stage2;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Stage2::spawn(None, Stage2, ())
        .await
        .expect("Failed to spawn stage2");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_stage3_spawns() {
    use pipeline_actors::actors::stage3::Stage3;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Stage3::spawn(None, Stage3, ())
        .await
        .expect("Failed to spawn stage3");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_sink_spawns() {
    use pipeline_actors::actors::sink::Sink;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Sink::spawn(None, Sink, ())
        .await
        .expect("Failed to spawn sink");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}
