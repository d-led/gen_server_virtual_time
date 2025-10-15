// Generated from ActorSimulation DSL
// Callback implementation for: load_balancer
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in load_balancer_actor.hpp

#include "load_balancer_actor.hpp"
#include <iostream>

void load_balancer_callbacks::on_request() {
  // TODO: Implement custom behavior for request
  // This is called when the actor sends a request message
  std::cout << "load_balancer: Sending request message" << std::endl;
}

