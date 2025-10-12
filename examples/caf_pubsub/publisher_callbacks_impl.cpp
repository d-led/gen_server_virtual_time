// Generated from ActorSimulation DSL
// Callback implementation for: publisher
//
// IMPLEMENT YOUR CUSTOM LOGIC HERE
// This file is meant to be edited - add your business logic!

#include "publisher_callbacks.hpp"
#include <iostream>

void publisher_callbacks::on_event() {
  // TODO: Implement custom behavior for event
  // This is called when the actor sends a event message
  std::cout << "publisher: Sending event message" << std::endl;
}

