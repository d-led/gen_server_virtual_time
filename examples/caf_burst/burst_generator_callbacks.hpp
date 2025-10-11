// Generated from ActorSimulation DSL
// Callback interface for: burst_generator
//
// CUSTOMIZE THIS FILE to add your own behavior!
// The generated actor code will call these methods.

#pragma once

class burst_generator_callbacks {
  public:
    virtual ~burst_generator_callbacks() = default;

    virtual void on_batch();
};
