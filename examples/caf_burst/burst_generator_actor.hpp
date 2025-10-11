// Generated from ActorSimulation DSL
// Actor: burst_generator

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "burst_generator_callbacks.hpp"


class burst_generator_actor : public caf::event_based_actor {
  public:
    burst_generator_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<burst_generator_callbacks> callbacks_;
    std::vector<caf::actor> targets_;

    int send_count_ = 0;
};
