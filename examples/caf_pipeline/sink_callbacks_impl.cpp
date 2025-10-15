// Generated from ActorSimulation DSL
// Callback implementation for: sink
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in sink_actor.hpp

#include "sink_actor.hpp"
#include <iostream>

void sink_callbacks::on_message() {
  // TODO: Implement custom behavior
  std::cout << "sink: Processing message" << std::endl;
}

