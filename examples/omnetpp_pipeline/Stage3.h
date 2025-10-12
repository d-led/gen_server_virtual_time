// Generated from ActorSimulation DSL
// Actor: stage3

#ifndef STAGE3_H
#define STAGE3_H

#include <omnetpp.h>

using namespace omnetpp;

class Stage3 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
