// Generated from ActorSimulation DSL
// Actor: stage2

#ifndef __STAGE2_H
#define __STAGE2_H

#include <omnetpp.h>

using namespace omnetpp;

class Stage2 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
