// Generated from ActorSimulation DSL
// Actor: publisher

#ifndef __PUBLISHER_H
#define __PUBLISHER_H

#include <omnetpp.h>

using namespace omnetpp;

class Publisher : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
