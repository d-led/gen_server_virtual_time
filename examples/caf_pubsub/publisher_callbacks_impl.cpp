// Generated from ActorSimulation DSL
// Callback implementation for: publisher
//
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!
// The interface is defined in publisher_actor.hpp

#include "publisher_actor.hpp"
#include <iostream>

void publisher_callbacks::on_event() {
  // TODO: Implement custom behavior for event
  // This is called when the actor sends a event message
  std::cout << "publisher: Sending event message" << std::endl;
}

