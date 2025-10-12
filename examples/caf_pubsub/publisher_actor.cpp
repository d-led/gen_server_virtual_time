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
    [=](event_atom) {
  callbacks_->on_event();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void publisher_actor::schedule_next_send() {
  // CAF 1.0: Use mail API instead of deprecated delayed_send
  mail(event_atom_v).delay(std::chrono::milliseconds(100)).send(this);
}

void publisher_actor::send_to_targets() {
  for (auto& target : targets_) {
    // CAF 1.0: Use mail API instead of send
    mail(msg_atom_v).send(target);
    send_count_++;
  }
}
