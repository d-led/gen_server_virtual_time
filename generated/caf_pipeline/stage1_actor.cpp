// Generated from ActorSimulation DSL
// Actor: stage1

#include "stage1_actor.hpp"
#include <iostream>

stage1_actor::stage1_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<stage1_callbacks>();
}

caf::behavior stage1_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
      // Default message handler
      send_to_targets();
      schedule_next_send();
    }
  };
}

void stage1_actor::schedule_next_send() {
  // No automatic sending pattern
}

void stage1_actor::send_to_targets() {
  for (auto& target : targets_) {
    send(target, caf::atom("msg"));
    send_count_++;
  }
}
