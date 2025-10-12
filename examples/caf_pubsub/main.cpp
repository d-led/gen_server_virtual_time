// Generated from ActorSimulation DSL
// Main entry point for PubSubActors

#include <caf/all.hpp>
#include <iostream>
#include <string>
#include "publisher_actor.hpp"
#include "subscriber1_actor.hpp"
#include "subscriber2_actor.hpp"
#include "subscriber3_actor.hpp"

using namespace caf;

int caf_main(actor_system& system) {
  // Spawn all actors
  auto publisher = system.spawn<publisher_actor>(std::vector<actor>{});
  auto subscriber1 = system.spawn<subscriber1_actor>(std::vector<actor>{});
  auto subscriber2 = system.spawn<subscriber2_actor>(std::vector<actor>{});
  auto subscriber3 = system.spawn<subscriber3_actor>(std::vector<actor>{});
  // Re-spawn publisher with proper targets
  publisher = system.spawn<publisher_actor>(std::vector<actor>{subscriber1, subscriber2, subscriber3});

  // Keep system alive - wait for user input to exit
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;
  std::cout << "Press Enter to stop..." << std::endl;
  
  // Keep the system running
  std::string line;
  std::getline(std::cin, line);

  return 0;
}

CAF_MAIN()
