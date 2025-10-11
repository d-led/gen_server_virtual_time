// Generated from ActorSimulation DSL
// Catch2 tests for BurstActors

#include <catch2/catch_test_macros.hpp>
#include <caf/all.hpp>
#include "processor_actor.hpp"
#include "burst_generator_actor.hpp"

using namespace caf;

TEST_CASE("Actor system can be initialized", "[system]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  REQUIRE(system.scheduler().num_workers() > 0);
}

TEST_CASE("processor_actor can be created", "[processor]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<processor_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("burst_generator_actor can be created", "[burst_generator]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<burst_generator_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("All actors can be spawned", "[actors]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto processor = system.spawn<processor_actor>(std::vector<actor>{});
  REQUIRE(processor != nullptr);
  
  auto burst_generator = system.spawn<burst_generator_actor>(std::vector<actor>{});
  REQUIRE(burst_generator != nullptr);
  
  // All actors spawned successfully
  SUCCEED("All actors created");
}

TEST_CASE("Actors can communicate", "[communication]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  // Spawn actors
  auto processor = system.spawn<processor_actor>(std::vector<actor>{});
  REQUIRE(processor != nullptr);
  
  auto burst_generator = system.spawn<burst_generator_actor>(std::vector<actor>{});
  REQUIRE(burst_generator != nullptr);
  
  // Actors are alive
  SUCCEED("Communication test placeholder");
}
