// Generated from ActorSimulation DSL
// Callback implementation for: processor
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in processor_actor.hpp

#include "processor_actor.hpp"
#include <iostream>

void processor_callbacks::on_message() {
  // TODO: Implement custom behavior
  std::cout << "processor: Processing message" << std::endl;
}

