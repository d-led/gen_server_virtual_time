// Generated from ActorSimulation DSL
// Actor: burst_generator

#ifndef BURSTGENERATOR_H
#define BURSTGENERATOR_H

#include <omnetpp.h>

using namespace omnetpp;

class BurstGenerator : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
