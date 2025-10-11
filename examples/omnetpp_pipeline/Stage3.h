// Generated from ActorSimulation DSL
// Actor: stage3

#ifndef __STAGE3_H
#define __STAGE3_H

#include <omnetpp.h>

using namespace omnetpp;

class Stage3 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
