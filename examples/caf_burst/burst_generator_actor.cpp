// Generated from ActorSimulation DSL
// Actor: burst_generator

#include "burst_generator_actor.hpp"
#include <iostream>

burst_generator_actor::burst_generator_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<burst_generator_callbacks>();
}

caf::behavior burst_generator_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
  callbacks_->on_batch();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void burst_generator_actor::schedule_next_send() {
  for (int i = 0; i < 10; i++) {
    delayed_send(this, std::chrono::milliseconds(1000), caf::atom("batch"));
  }
}

void burst_generator_actor::send_to_targets() {
  for (auto& target : targets_) {
    send(target, caf::atom("msg"));
    send_count_++;
  }
}
