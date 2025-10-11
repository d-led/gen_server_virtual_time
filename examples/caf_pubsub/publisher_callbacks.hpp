// Generated from ActorSimulation DSL
// Callback interface for: publisher
//
// CUSTOMIZE THIS FILE to add your own behavior!
// The generated actor code will call these methods.

#pragma once

class publisher_callbacks {
  public:
    virtual ~publisher_callbacks() = default;

    virtual void on_event();
};
