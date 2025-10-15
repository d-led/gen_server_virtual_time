// Generated from ActorSimulation DSL
// Actor: processor
// DO NOT EDIT - This file is auto-generated

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"

// Callback interface for: processor
// This is the contract - do not modify
class processor_callbacks {
  public:
    virtual ~processor_callbacks() = default;

    virtual void on_message();
};


class processor_actor : public caf::event_based_actor {
  public:
    processor_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<processor_callbacks> callbacks_;

};
