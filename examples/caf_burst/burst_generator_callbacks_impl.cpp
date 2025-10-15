// Generated from ActorSimulation DSL
// Callback implementation for: burst_generator
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in burst_generator_actor.hpp

#include "burst_generator_actor.hpp"
#include <iostream>

void burst_generator_callbacks::on_batch() {
  // TODO: Implement custom behavior for batch
  // This is called when the actor sends a batch message
  std::cout << "burst_generator: Sending batch message" << std::endl;
}

