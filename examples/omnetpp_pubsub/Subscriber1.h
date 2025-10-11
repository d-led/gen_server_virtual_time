// Generated from ActorSimulation DSL
// Actor: subscriber1

#ifndef __SUBSCRIBER1_H
#define __SUBSCRIBER1_H

#include <omnetpp.h>

using namespace omnetpp;

class Subscriber1 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
