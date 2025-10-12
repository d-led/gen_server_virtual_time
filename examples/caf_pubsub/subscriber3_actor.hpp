// Generated from ActorSimulation DSL
// Actor: subscriber3

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "subscriber3_callbacks.hpp"

class subscriber3_actor : public caf::event_based_actor {
  public:
    subscriber3_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<subscriber3_callbacks> callbacks_;

    int send_count_ = 0;
};
