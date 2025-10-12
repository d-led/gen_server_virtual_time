// Generated from ActorSimulation DSL
// Actor: sink

#include "sink_actor.hpp"
#include <iostream>

sink_actor::sink_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<sink_callbacks>();
}

caf::behavior sink_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
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
