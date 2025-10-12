// Generated from ActorSimulation DSL
// Main entry point for PipelineActors

#include <caf/all.hpp>
#include <iostream>
#include "source_actor.hpp"
#include "stage1_actor.hpp"
#include "stage2_actor.hpp"
#include "stage3_actor.hpp"
#include "sink_actor.hpp"

using namespace caf;

int caf_main(actor_system& system) {
  // Spawn all actors
  auto source = system.spawn<source_actor>(std::vector<actor>{});
  auto stage1 = system.spawn<stage1_actor>(std::vector<actor>{});
  auto stage2 = system.spawn<stage2_actor>(std::vector<actor>{});
  auto stage3 = system.spawn<stage3_actor>(std::vector<actor>{});
  auto sink = system.spawn<sink_actor>(std::vector<actor>{});

  // Keep system alive
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;

  return 0;
}

CAF_MAIN()
