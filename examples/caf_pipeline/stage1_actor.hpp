// Generated from ActorSimulation DSL
// Actor: stage1
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: stage1
// This is the contract - do not modify
class stage1_callbacks {
  public:
    virtual ~stage1_callbacks() = default;

    virtual void on_message();
};


class stage1_actor : public caf::event_based_actor {
  public:
    stage1_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<stage1_callbacks> callbacks_;
    std::vector<caf::actor> targets_;
    int send_count_ = 0;

};
