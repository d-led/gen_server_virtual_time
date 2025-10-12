// Generated from ActorSimulation DSL
// Actor: server3

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "server3_callbacks.hpp"

class server3_actor : public caf::event_based_actor {
  public:
    server3_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<server3_callbacks> callbacks_;
    std::vector<caf::actor> targets_;
    int send_count_ = 0;

};
