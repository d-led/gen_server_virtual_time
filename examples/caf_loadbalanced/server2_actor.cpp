// Generated from ActorSimulation DSL
// Actor: server2

#include "server2_actor.hpp"
#include <iostream>

server2_actor::server2_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<server2_callbacks>();
}

caf::behavior server2_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void server2_actor::schedule_next_send() {
  // No automatic sending pattern
}

void server2_actor::send_to_targets() {
  for (auto& target : targets_) {
    send(target, caf::atom("msg"));
    send_count_++;
  }
}
