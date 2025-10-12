// Generated from ActorSimulation DSL
// Main entry point for BurstActors

#include <caf/all.hpp>
#include <iostream>
#include "processor_actor.hpp"
#include "burst_generator_actor.hpp"

using namespace caf;

int caf_main(actor_system& system) {
  // Spawn all actors
  auto processor = system.spawn<processor_actor>(std::vector<actor>{});
  auto burst_generator = system.spawn<burst_generator_actor>(std::vector<actor>{});

  // Keep system alive
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;

  return 0;
}

CAF_MAIN()
