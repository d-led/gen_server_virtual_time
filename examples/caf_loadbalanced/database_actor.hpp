// Generated from ActorSimulation DSL
// Actor: database

#pragma once

#include <caf/all.hpp>
#include <chrono>
#include <vector>
#include "atoms.hpp"
#include "database_callbacks.hpp"

class database_actor : public caf::event_based_actor {
  public:
    database_actor(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

    caf::behavior make_behavior() override;

  private:
    void schedule_next_send();
    void send_to_targets();
    std::shared_ptr<database_callbacks> callbacks_;

};
