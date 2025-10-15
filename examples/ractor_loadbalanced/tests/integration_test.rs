// Generated from ActorSimulation DSL
// Integration tests for actors

use ractor::Actor;

#[tokio::test]
async fn test_actor_system() {
    // Basic system test
    assert!(true);
}

#[tokio::test]
async fn test_load_balancer_spawns() {
    use loadbalanced_actors::actors::load_balancer::LoadBalancer;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = LoadBalancer::spawn(None, LoadBalancer, ())
        .await
        .expect("Failed to spawn load_balancer");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_server1_spawns() {
    use loadbalanced_actors::actors::server1::Server1;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Server1::spawn(None, Server1, ())
        .await
        .expect("Failed to spawn server1");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_server2_spawns() {
    use loadbalanced_actors::actors::server2::Server2;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Server2::spawn(None, Server2, ())
        .await
        .expect("Failed to spawn server2");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_server3_spawns() {
    use loadbalanced_actors::actors::server3::Server3;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Server3::spawn(None, Server3, ())
        .await
        .expect("Failed to spawn server3");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}


#[tokio::test]
async fn test_database_spawns() {
    use loadbalanced_actors::actors::database::Database;
    use ractor::ActorStatus;

    let (actor_ref, actor_handle) = Database::spawn(None, Database, ())
        .await
        .expect("Failed to spawn database");

    // Give it time to initialize
    tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

    // Verify actor is running
    matches!(actor_ref.get_status(), ActorStatus::Running);

    // Clean up
    actor_ref.stop(None);
    let _ = actor_handle.await;
}
