// Generated from ActorSimulation DSL
// Actor: subscriber2

#ifndef __SUBSCRIBER2_H
#define __SUBSCRIBER2_H

#include <omnetpp.h>

using namespace omnetpp;

class Subscriber2 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
