// Generated from ActorSimulation DSL
// Actor: subscriber3

#ifndef __SUBSCRIBER3_H
#define __SUBSCRIBER3_H

#include <omnetpp.h>

using namespace omnetpp;

class Subscriber3 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
