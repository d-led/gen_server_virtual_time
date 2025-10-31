// Generated from ActorSimulation DSL
// Actor: consumer

#ifndef CONSUMER_H
#define CONSUMER_H

#include <omnetpp.h>

using namespace omnetpp;

class Consumer : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
