// Generated from ActorSimulation DSL
// Actor: server2
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: server2
// This is the contract - do not modify
class server2_callbacks {
  public:
    virtual ~server2_callbacks() = default;

    virtual void on_message();
};


class server2_actor : public caf::event_based_actor {
  public:
    server2_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<server2_callbacks> callbacks_;
    std::vector<caf::actor> targets_;
    int send_count_ = 0;

};
