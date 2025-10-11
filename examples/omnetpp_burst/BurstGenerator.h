// Generated from ActorSimulation DSL
// Actor: burst_generator

#ifndef __BURSTGENERATOR_H
#define __BURSTGENERATOR_H

#include <omnetpp.h>

using namespace omnetpp;

class BurstGenerator : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
