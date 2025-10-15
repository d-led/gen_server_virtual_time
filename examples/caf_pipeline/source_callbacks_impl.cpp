// Generated from ActorSimulation DSL
// Callback implementation for: source
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in source_actor.hpp

#include "source_actor.hpp"
#include <iostream>

void source_callbacks::on_data() {
  // TODO: Implement custom behavior for data
  // This is called when the actor sends a data message
  std::cout << "source: Sending data message" << std::endl;
}

