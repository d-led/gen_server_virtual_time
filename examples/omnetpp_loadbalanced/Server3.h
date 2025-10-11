// Generated from ActorSimulation DSL
// Actor: server3

#ifndef __SERVER3_H
#define __SERVER3_H

#include <omnetpp.h>

using namespace omnetpp;

class Server3 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
