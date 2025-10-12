// Generated from ActorSimulation DSL
// Main entry point for BurstActors

#include <caf/all.hpp>
#include <iostream>
#include <string>
#include "processor_actor.hpp"
#include "burst_generator_actor.hpp"

using namespace caf;

int caf_main(actor_system& system) {
  // Spawn all actors
  auto processor = system.spawn<processor_actor>(std::vector<actor>{});
  auto burst_generator = system.spawn<burst_generator_actor>(std::vector<actor>{});
  // Re-spawn burst_generator with proper targets
  burst_generator = system.spawn<burst_generator_actor>(std::vector<actor>{processor});

  // Keep system alive - wait for user input to exit
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;
  std::cout << "Press Enter to stop..." << std::endl;
  
  // Keep the system running
  std::string line;
  std::getline(std::cin, line);

  return 0;
}

CAF_MAIN()
