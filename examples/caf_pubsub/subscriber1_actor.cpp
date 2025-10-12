// Generated from ActorSimulation DSL
// Actor: subscriber1

#include "subscriber1_actor.hpp"
#include <iostream>

subscriber1_actor::subscriber1_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg) {
  (void)targets; // Unused but required for API consistency
  callbacks_ = std::make_shared<subscriber1_callbacks>();
}

caf::behavior subscriber1_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](event_atom) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void subscriber1_actor::schedule_next_send() {
  // No automatic sending pattern
}

void subscriber1_actor::send_to_targets() {
  // No targets to send to
}
