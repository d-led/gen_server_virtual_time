// Generated from ActorSimulation DSL
// Actor: stage3

#include "stage3_actor.hpp"
#include <iostream>

stage3_actor::stage3_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<stage3_callbacks>();
}

caf::behavior stage3_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void stage3_actor::schedule_next_send() {
  // No automatic sending pattern
}

void stage3_actor::send_to_targets() {
  for (auto& target : targets_) {
    send(target, caf::atom("msg"));
    send_count_++;
  }
}
