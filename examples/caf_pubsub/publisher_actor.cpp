// Generated from ActorSimulation DSL
// Actor: publisher

#include "publisher_actor.hpp"
#include <iostream>

publisher_actor::publisher_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<publisher_callbacks>();
}

caf::behavior publisher_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](caf::atom_value msg) {
  callbacks_->on_event();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void publisher_actor::schedule_next_send() {
  delayed_send(this, std::chrono::milliseconds(100), caf::atom("event"));
}

void publisher_actor::send_to_targets() {
  for (auto& target : targets_) {
    send(target, caf::atom("msg"));
    send_count_++;
  }
}
