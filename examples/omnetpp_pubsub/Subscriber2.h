// Generated from ActorSimulation DSL
// Actor: subscriber2

#ifndef SUBSCRIBER2_H
#define SUBSCRIBER2_H

#include <omnetpp.h>

using namespace omnetpp;

class Subscriber2 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
