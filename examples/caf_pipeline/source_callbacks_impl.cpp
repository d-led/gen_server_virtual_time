// Generated from ActorSimulation DSL
// Callback implementation for: source
//
// IMPLEMENT YOUR CUSTOM LOGIC HERE
// This file is meant to be edited - add your business logic!

#include "source_callbacks.hpp"
#include <iostream>

void source_callbacks::on_data() {
  // TODO: Implement custom behavior for data
  // This is called when the actor sends a data message
  std::cout << "source: Sending data message" << std::endl;
}

