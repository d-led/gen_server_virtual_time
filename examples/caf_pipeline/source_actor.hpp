// Generated from ActorSimulation DSL
// Actor: source
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: source
// This is the contract - do not modify
class source_callbacks {
  public:
    virtual ~source_callbacks() = default;

    virtual void on_data();
};


class source_actor : public caf::event_based_actor {
  public:
    source_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<source_callbacks> callbacks_;
    std::vector<caf::actor> targets_;
    int send_count_ = 0;

};
