// Generated from ActorSimulation DSL
// Actor: stage2

#ifndef STAGE2_H
#define STAGE2_H

#include <omnetpp.h>

using namespace omnetpp;

class Stage2 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
