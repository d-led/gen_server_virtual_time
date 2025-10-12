// Generated from ActorSimulation DSL
// Actor: subscriber1

#ifndef SUBSCRIBER1_H
#define SUBSCRIBER1_H

#include <omnetpp.h>

using namespace omnetpp;

class Subscriber1 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
