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
    [=](batch_atom) {
  callbacks_->on_batch();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void burst_generator_actor::schedule_next_send() {
  // CAF 1.0: Use mail API instead of deprecated delayed_send
  for (int i = 0; i < 10; i++) {
    mail(batch_atom_v).delay(std::chrono::milliseconds(1000)).send(this);
  }
}

void burst_generator_actor::send_to_targets() {
  for (auto& target : targets_) {
    // CAF 1.0: Use mail API instead of send
    mail(msg_atom_v).send(target);
    send_count_++;
  }
}
