// Generated from ActorSimulation DSL
// Actor: producer

#ifndef PRODUCER_H
#define PRODUCER_H

#include <omnetpp.h>

using namespace omnetpp;

class Producer : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
