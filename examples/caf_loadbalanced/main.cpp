// Generated from ActorSimulation DSL
// Main entry point for LoadBalancedActors

#include <caf/all.hpp>
#include <iostream>
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

  // Keep system alive
  std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;
  
  return 0;
}

CAF_MAIN()
