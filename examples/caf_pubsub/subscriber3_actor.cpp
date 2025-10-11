// Generated from ActorSimulation DSL
// Actor: subscriber3

#include "subscriber3_actor.hpp"
#include <iostream>

subscriber3_actor::subscriber3_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<subscriber3_callbacks>();
}

caf::behavior subscriber3_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void subscriber3_actor::schedule_next_send() {
  // No automatic sending pattern
}

void subscriber3_actor::send_to_targets() {
  // No targets to send to
}
