// Generated from ActorSimulation DSL
// Actor: processor

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "processor_callbacks.hpp"

class processor_actor : public caf::event_based_actor {
  public:
    processor_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<processor_callbacks> callbacks_;

};
