// Generated from ActorSimulation DSL
// Actor: processor

#include "processor_actor.hpp"
#include <iostream>

processor_actor::processor_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<processor_callbacks>();
}

caf::behavior processor_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](event_atom) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void processor_actor::schedule_next_send() {
  // No automatic sending pattern
}

void processor_actor::send_to_targets() {
  // No targets to send to
}
