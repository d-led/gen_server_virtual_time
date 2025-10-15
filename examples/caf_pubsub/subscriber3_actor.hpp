// Generated from ActorSimulation DSL
// Actor: subscriber3
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: subscriber3
// This is the contract - do not modify
class subscriber3_callbacks {
  public:
    virtual ~subscriber3_callbacks() = default;

    virtual void on_message();
};


class subscriber3_actor : public caf::event_based_actor {
  public:
    subscriber3_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<subscriber3_callbacks> callbacks_;

};
