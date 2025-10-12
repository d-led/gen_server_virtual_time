// Generated from ActorSimulation DSL
// Actor: sink

#include "sink_actor.hpp"
#include <iostream>

sink_actor::sink_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg) {
  (void)targets; // Unused but required for API consistency
  callbacks_ = std::make_shared<sink_callbacks>();
}

caf::behavior sink_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](event_atom) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void sink_actor::schedule_next_send() {
  // No automatic sending pattern
}

void sink_actor::send_to_targets() {
  // No targets to send to
}
