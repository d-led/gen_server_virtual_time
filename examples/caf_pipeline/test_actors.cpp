// Generated from ActorSimulation DSL
// Catch2 tests for PipelineActors

#include <catch2/catch_test_macros.hpp>
#include <caf/all.hpp>
#include "source_actor.hpp"
#include "stage1_actor.hpp"
#include "stage2_actor.hpp"
#include "stage3_actor.hpp"
#include "sink_actor.hpp"

using namespace caf;

TEST_CASE("Actor system can be initialized", "[system]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  REQUIRE(system.scheduler().num_workers() > 0);
}

TEST_CASE("source_actor can be created", "[source]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<source_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("stage1_actor can be created", "[stage1]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<stage1_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("stage2_actor can be created", "[stage2]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<stage2_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("stage3_actor can be created", "[stage3]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<stage3_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("sink_actor can be created", "[sink]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto actor = system.spawn<sink_actor>(std::vector<caf::actor>{});
  REQUIRE(actor != nullptr);
}


TEST_CASE("All actors can be spawned", "[actors]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  auto source = system.spawn<source_actor>(std::vector<actor>{});
  REQUIRE(source != nullptr);
  
  auto stage1 = system.spawn<stage1_actor>(std::vector<actor>{});
  REQUIRE(stage1 != nullptr);
  
  auto stage2 = system.spawn<stage2_actor>(std::vector<actor>{});
  REQUIRE(stage2 != nullptr);
  
  auto stage3 = system.spawn<stage3_actor>(std::vector<actor>{});
  REQUIRE(stage3 != nullptr);
  
  auto sink = system.spawn<sink_actor>(std::vector<actor>{});
  REQUIRE(sink != nullptr);
  
  // All actors spawned successfully
  SUCCEED("All actors created");
}

TEST_CASE("Actors can communicate", "[communication]") {
  actor_system_config cfg;
  actor_system system{cfg};
  
  // Spawn actors
  auto source = system.spawn<source_actor>(std::vector<actor>{});
  REQUIRE(source != nullptr);
  
  auto stage1 = system.spawn<stage1_actor>(std::vector<actor>{});
  REQUIRE(stage1 != nullptr);
  
  auto stage2 = system.spawn<stage2_actor>(std::vector<actor>{});
  REQUIRE(stage2 != nullptr);
  
  auto stage3 = system.spawn<stage3_actor>(std::vector<actor>{});
  REQUIRE(stage3 != nullptr);
  
  auto sink = system.spawn<sink_actor>(std::vector<actor>{});
  REQUIRE(sink != nullptr);
  
  // Actors are alive
  SUCCEED("Communication test placeholder");
}
