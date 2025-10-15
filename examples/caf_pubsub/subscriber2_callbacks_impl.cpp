// Generated from ActorSimulation DSL
// Callback implementation for: subscriber2
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in subscriber2_actor.hpp

#include "subscriber2_actor.hpp"
#include <iostream>

void subscriber2_callbacks::on_message() {
  // TODO: Implement custom behavior
  std::cout << "subscriber2: Processing message" << std::endl;
}

