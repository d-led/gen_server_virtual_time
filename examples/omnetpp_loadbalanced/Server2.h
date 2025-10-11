// Generated from ActorSimulation DSL
// Actor: server2

#ifndef __SERVER2_H
#define __SERVER2_H

#include <omnetpp.h>

using namespace omnetpp;

class Server2 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
