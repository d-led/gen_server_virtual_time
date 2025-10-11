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
    [=](caf::atom_value msg) {
  callbacks_->on_data();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void source_actor::schedule_next_send() {
  delayed_send(this, std::chrono::milliseconds(20), caf::atom("data"));
}

void source_actor::send_to_targets() {
  for (auto& target : targets_) {
    send(target, caf::atom("msg"));
    send_count_++;
  }
}
