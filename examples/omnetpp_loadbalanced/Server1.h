// Generated from ActorSimulation DSL
// Actor: server1

#ifndef __SERVER1_H
#define __SERVER1_H

#include <omnetpp.h>

using namespace omnetpp;

class Server1 : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
