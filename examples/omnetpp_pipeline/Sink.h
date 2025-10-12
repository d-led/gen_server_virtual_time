// Generated from ActorSimulation DSL
// Actor: sink

#ifndef SINK_H
#define SINK_H

#include <omnetpp.h>

using namespace omnetpp;

class Sink : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
