// Generated from ActorSimulation DSL
// Actor: load_balancer

#include "load_balancer_actor.hpp"
#include <iostream>

load_balancer_actor::load_balancer_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
  : caf::event_based_actor(cfg), targets_(targets) {
  callbacks_ = std::make_shared<load_balancer_callbacks>();
}

caf::behavior load_balancer_actor::make_behavior() {
  schedule_next_send();

  return {
    [=](request_atom) {
  callbacks_->on_request();
      send_to_targets();
      schedule_next_send();
    }
  };
}

void load_balancer_actor::schedule_next_send() {
  delayed_send(this, std::chrono::milliseconds(10), request_atom_v);
}

void load_balancer_actor::send_to_targets() {
  for (auto& target : targets_) {
    // CAF 1.0: Use mail API instead of send
    mail(msg_atom_v).send(target);
    send_count_++;
  }
}
