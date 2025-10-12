// Generated from ActorSimulation DSL
// Actor: processor

#ifndef PROCESSOR_H
#define PROCESSOR_H

#include <omnetpp.h>

using namespace omnetpp;

class Processor : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
