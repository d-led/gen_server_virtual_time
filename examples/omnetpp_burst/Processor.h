// Generated from ActorSimulation DSL
// Actor: processor

#ifndef __PROCESSOR_H
#define __PROCESSOR_H

#include <omnetpp.h>

using namespace omnetpp;

class Processor : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
