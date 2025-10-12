// Generated from ActorSimulation DSL
// Actor: source

#include "source_actor.hpp"
#include <iostream>

source_actor::source_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<source_callbacks>();
}

caf::behavior source_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](data_atom) {
  callbacks_->on_data();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void source_actor::schedule_next_send() {
  // CAF 1.0: Use mail API instead of deprecated delayed_send
  mail(data_atom_v).delay(std::chrono::milliseconds(20)).send(this);
}

void source_actor::send_to_targets() {
  for (auto& target : targets_) {
    // CAF 1.0: Use mail API instead of send
    mail(msg_atom_v).send(target);
    send_count_++;
  }
}
