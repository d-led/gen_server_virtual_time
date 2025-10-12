// Generated from ActorSimulation DSL
// Actor: server1

#include "server1_actor.hpp"
#include <iostream>

server1_actor::server1_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<server1_callbacks>();
}

caf::behavior server1_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](event_atom) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void server1_actor::schedule_next_send() {
  // No automatic sending pattern
}

void server1_actor::send_to_targets() {
  for (auto& target : targets_) {
    // CAF 1.0: Use mail API instead of send
    mail(msg_atom_v).send(target);
    send_count_++;
  }
}
