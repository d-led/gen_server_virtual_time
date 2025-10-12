// Generated from ActorSimulation DSL
// Actor: load_balancer

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "load_balancer_callbacks.hpp"

class load_balancer_actor : public caf::event_based_actor {
  public:
    load_balancer_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<load_balancer_callbacks> callbacks_;
    std::vector<caf::actor> targets_;

    int send_count_ = 0;
};
