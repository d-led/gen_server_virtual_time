// Generated from ActorSimulation DSL
// Actor: subscriber3

#ifndef SUBSCRIBER3_H
#define SUBSCRIBER3_H

#include <omnetpp.h>

using namespace omnetpp;

class Subscriber3 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
