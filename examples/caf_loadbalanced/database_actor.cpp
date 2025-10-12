// Generated from ActorSimulation DSL
// Actor: database

#include "database_actor.hpp"
#include <iostream>

database_actor::database_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg) {
  (void)targets; // Unused but required for API consistency
  callbacks_ = std::make_shared<database_callbacks>();
}

caf::behavior database_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](event_atom) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void database_actor::schedule_next_send() {
  // No automatic sending pattern
}

void database_actor::send_to_targets() {
  // No targets to send to
}
