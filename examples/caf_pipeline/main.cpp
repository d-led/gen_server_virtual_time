// Generated from ActorSimulation DSL
// Main entry point for PipelineActors

#include <caf/all.hpp>
#include <iostream>
#include <string>
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
  // Re-spawn source with proper targets
  source = system.spawn<source_actor>(std::vector<actor>{stage1});
  // Re-spawn stage1 with proper targets
  stage1 = system.spawn<stage1_actor>(std::vector<actor>{stage2});
  // Re-spawn stage2 with proper targets
  stage2 = system.spawn<stage2_actor>(std::vector<actor>{stage3});
  // Re-spawn stage3 with proper targets
  stage3 = system.spawn<stage3_actor>(std::vector<actor>{sink});

  // Keep system alive - wait for user input to exit
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;
  std::cout << "Press Enter to stop..." << std::endl;
  
  // Keep the system running
  std::string line;
  std::getline(std::cin, line);

  return 0;
}

CAF_MAIN()
