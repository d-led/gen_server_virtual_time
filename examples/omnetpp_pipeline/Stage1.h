// Generated from ActorSimulation DSL
// Actor: stage1

#ifndef STAGE1_H
#define STAGE1_H

#include <omnetpp.h>

using namespace omnetpp;

class Stage1 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
