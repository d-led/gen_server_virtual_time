// Generated from ActorSimulation DSL
// Callback interface for: database
//
// CUSTOMIZE THIS FILE to add your own behavior!
// The generated actor code will call these methods.

#pragma once

class database_callbacks {
  public:
    virtual ~database_callbacks() = default;

    virtual void on_message();
};
