// Generated from ActorSimulation DSL
// Callback interface for: load_balancer
//
// CUSTOMIZE THIS FILE to add your own behavior!
// The generated actor code will call these methods.

#pragma once

class load_balancer_callbacks {
  public:
    virtual ~load_balancer_callbacks() = default;

    virtual void on_request();
};
