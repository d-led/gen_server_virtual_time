// Generated from ActorSimulation DSL
// Actor: subscriber1
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: subscriber1
// This is the contract - do not modify
class subscriber1_callbacks {
  public:
    virtual ~subscriber1_callbacks() = default;

    virtual void on_message();
};


class subscriber1_actor : public caf::event_based_actor {
  public:
    subscriber1_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<subscriber1_callbacks> callbacks_;

};
