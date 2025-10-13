// Generated from ActorSimulation DSL
// Main entry point for LoadBalancedActors

#include <caf/all.hpp>
#include <iostream>
#include <string>
#include "load_balancer_actor.hpp"
#include "server1_actor.hpp"
#include "server2_actor.hpp"
#include "server3_actor.hpp"
#include "database_actor.hpp"

using namespace caf;

int caf_main(actor_system& system) {
  // Spawn all actors
  auto load_balancer = system.spawn<load_balancer_actor>(std::vector<actor>{});
  auto server1 = system.spawn<server1_actor>(std::vector<actor>{});
  auto server2 = system.spawn<server2_actor>(std::vector<actor>{});
  auto server3 = system.spawn<server3_actor>(std::vector<actor>{});
  auto database = system.spawn<database_actor>(std::vector<actor>{});
  // Re-spawn load_balancer with proper targets
  load_balancer = system.spawn<load_balancer_actor>(std::vector<actor>{server1, server2, server3});
  // Re-spawn server1 with proper targets
  server1 = system.spawn<server1_actor>(std::vector<actor>{database});
  // Re-spawn server2 with proper targets
  server2 = system.spawn<server2_actor>(std::vector<actor>{database});
  // Re-spawn server3 with proper targets
  server3 = system.spawn<server3_actor>(std::vector<actor>{database});

  // Keep system alive - wait for user input to exit
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;
  std::cout << "Press Enter to stop..." << std::endl;

  // Keep the system running
  std::string line;
  std::getline(std::cin, line);

  return 0;
}

CAF_MAIN()
