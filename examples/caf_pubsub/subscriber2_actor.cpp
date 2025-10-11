// Generated from ActorSimulation DSL
// Actor: subscriber2

#include "subscriber2_actor.hpp"
#include <iostream>

subscriber2_actor::subscriber2_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<subscriber2_callbacks>();
}

caf::behavior subscriber2_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void subscriber2_actor::schedule_next_send() {
  // No automatic sending pattern
}

void subscriber2_actor::send_to_targets() {
  // No targets to send to
}
