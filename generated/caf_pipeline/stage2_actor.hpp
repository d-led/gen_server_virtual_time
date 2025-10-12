// Generated from ActorSimulation DSL
// Actor: stage2

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "stage2_callbacks.hpp"


class stage2_actor : public caf::event_based_actor {
  public:
    stage2_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<stage2_callbacks> callbacks_;
    std::vector<caf::actor> targets_;

    int send_count_ = 0;
};
