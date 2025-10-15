// Generated from ActorSimulation DSL
// Callback implementation for: subscriber1
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in subscriber1_actor.hpp

#include "subscriber1_actor.hpp"
#include <iostream>

void subscriber1_callbacks::on_message() {
  // TODO: Implement custom behavior
  std::cout << "subscriber1: Processing message" << std::endl;
}

