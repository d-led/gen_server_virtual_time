// Generated from ActorSimulation DSL
// Actor: sink

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "sink_callbacks.hpp"

class sink_actor : public caf::event_based_actor {
  public:
    sink_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<sink_callbacks> callbacks_;

};
