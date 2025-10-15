// Generated from ActorSimulation DSL
// Actor: burst_generator
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: burst_generator
// This is the contract - do not modify
class burst_generator_callbacks {
  public:
    virtual ~burst_generator_callbacks() = default;

    virtual void on_batch();
};


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
