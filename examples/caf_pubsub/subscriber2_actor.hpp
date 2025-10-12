// Generated from ActorSimulation DSL
// Actor: subscriber2

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "subscriber2_callbacks.hpp"

class subscriber2_actor : public caf::event_based_actor {
  public:
    subscriber2_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<subscriber2_callbacks> callbacks_;

};
