// Generated from ActorSimulation DSL
// Actor: stage1

#ifndef __STAGE1_H
#define __STAGE1_H

#include <omnetpp.h>

using namespace omnetpp;

class Stage1 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
