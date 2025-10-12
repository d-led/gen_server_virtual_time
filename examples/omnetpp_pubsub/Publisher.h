// Generated from ActorSimulation DSL
// Actor: publisher

#ifndef PUBLISHER_H
#define PUBLISHER_H

#include <omnetpp.h>

using namespace omnetpp;

class Publisher : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
