// Generated from ActorSimulation DSL
// Actor: publisher
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: publisher
// This is the contract - do not modify
class publisher_callbacks {
  public:
    virtual ~publisher_callbacks() = default;

    virtual void on_event();
};


class publisher_actor : public caf::event_based_actor {
  public:
    publisher_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<publisher_callbacks> callbacks_;
    std::vector<caf::actor> targets_;
    int send_count_ = 0;

};
